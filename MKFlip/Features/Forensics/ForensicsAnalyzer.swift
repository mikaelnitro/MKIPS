import Foundation

/// Resultado da análise forense de um arquivo. Imutável — o original nunca é
/// alterado; trabalhamos apenas sobre uma cópia dos bytes em memória.
struct FileAnalysis: Sendable {
    let name: String
    let fileExtension: String
    let byteCount: Int
    let detectedType: FileType?
    let declaredVsDetectedMismatch: Bool
    let sha256: String
    let sha1: String
    let md5: String
    let hexLines: [String]
    let hexTruncated: Bool
    let strings: [String]
    let interestingStrings: [String]
    let entropy: Double          // 0–8 bits/byte, indica compressão/cifra

    /// Converte para um relatório exportável.
    func asReport() -> Report {
        var overview = [
            "Arquivo: \(name)",
            "Extensão declarada: .\(fileExtension.isEmpty ? "—" : fileExtension)",
            "Tamanho: \(byteCount) bytes",
            "Tipo detectado: \(detectedType.map { "\($0.name) (\($0.mime))" } ?? "desconhecido")",
            "Entropia: \(String(format: "%.2f", entropy)) bits/byte"
        ]
        if declaredVsDetectedMismatch {
            overview.append("⚠︎ Extensão NÃO corresponde ao conteúdo detectado.")
        }
        return Report(
            tool: "Digital Forensics",
            title: "Análise de \(name)",
            subject: name,
            sections: [
                .init(heading: "Visão geral", lines: overview),
                .init(heading: "Hashes", lines: [
                    "MD5    : \(md5)", "SHA-1  : \(sha1)", "SHA-256: \(sha256)"
                ]),
                .init(heading: "Strings de interesse",
                      lines: interestingStrings.isEmpty ? ["(nenhuma)"] : Array(interestingStrings.prefix(30)))
            ]
        )
    }
}

enum ForensicsAnalyzer {

    static func analyze(data: Data, name: String) -> FileAnalysis {
        let ext = (name as NSString).pathExtension.lowercased()
        let detected = FileSignature.detect(data)

        let mismatch: Bool = {
            guard let detected, !ext.isEmpty else { return false }
            let n = detected.name.lowercased()
            // Checagem simples: a extensão aparece no nome do tipo detectado?
            let compatible = n.contains(ext)
                || (ext == "jpg" && n.contains("jpeg"))
                || (["docx","xlsx","pptx","apk","jar"].contains(ext) && n.contains("zip"))
            return !compatible
        }()

        let allStrings = StringsExtractor.extract(from: data)
        let hexLines = HexDump.lines(from: data, maxBytes: 4096)

        return FileAnalysis(
            name: name,
            fileExtension: ext,
            byteCount: data.count,
            detectedType: detected,
            declaredVsDetectedMismatch: mismatch,
            sha256: HashEngine.hash(data, with: .sha256),
            sha1: HashEngine.hash(data, with: .sha1),
            md5: HashEngine.hash(data, with: .md5),
            hexLines: hexLines,
            hexTruncated: data.count > 4096,
            strings: allStrings,
            interestingStrings: StringsExtractor.interesting(allStrings),
            entropy: shannonEntropy(data)
        )
    }

    /// Entropia de Shannon em bits/byte. ~8.0 sugere dados comprimidos/cifrados.
    static func shannonEntropy(_ data: Data) -> Double {
        guard !data.isEmpty else { return 0 }
        var counts = [Int](repeating: 0, count: 256)
        for byte in data { counts[Int(byte)] += 1 }
        let total = Double(data.count)
        return counts.reduce(0.0) { acc, c in
            guard c > 0 else { return acc }
            let p = Double(c) / total
            return acc - p * log2(p)
        }
    }
}
