import Foundation

/// Comparação binária de dois arquivos.
struct FileComparison: Sendable {
    let sameSize: Bool
    let sizeA: Int
    let sizeB: Int
    let identical: Bool
    let firstDiffOffset: Int?    // nil se idênticos (até o menor comprimento)
    let sameLeadingBytes: Int    // quantos bytes iniciais coincidem
    let sha256A: String
    let sha256B: String
}

enum FileComparator {
    static func compare(_ a: Data, _ b: Data) -> FileComparison {
        let bytesA = [UInt8](a)
        let bytesB = [UInt8](b)
        let minLen = min(bytesA.count, bytesB.count)
        var firstDiff: Int? = nil
        var i = 0
        while i < minLen {
            if bytesA[i] != bytesB[i] { firstDiff = i; break }
            i += 1
        }
        let identical = a.count == b.count && firstDiff == nil
        return FileComparison(
            sameSize: a.count == b.count, sizeA: a.count, sizeB: b.count,
            identical: identical, firstDiffOffset: firstDiff,
            sameLeadingBytes: firstDiff ?? minLen,
            sha256A: HashEngine.hash(a, with: .sha256),
            sha256B: HashEngine.hash(b, with: .sha256)
        )
    }
}

/// Base de conhecimento estática e honesta sobre formatos/protocolos comuns.
/// Conteúdo educacional fixo — não "inventa" análise.
struct ProtocolInfo: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let summary: String
    let structure: [String]
}

enum ProtocolLibrary {
    static let all: [ProtocolInfo] = [
        ProtocolInfo(name: "PNG",
            summary: "Imagem raster sem perdas, baseada em chunks.",
            structure: ["Assinatura: 89 50 4E 47 0D 0A 1A 0A",
                        "Chunks: IHDR, PLTE, IDAT, IEND",
                        "Cada chunk: tamanho(4) + tipo(4) + dados + CRC32(4)"]),
        ProtocolInfo(name: "JPEG",
            summary: "Imagem comprimida com perdas, baseada em segmentos marcadores.",
            structure: ["SOI: FF D8", "APPn/segmentos: FF Ex", "Dados comprimidos", "EOI: FF D9"]),
        ProtocolInfo(name: "ZIP",
            summary: "Contêiner compactado; base de APK, DOCX, JAR, EPUB.",
            structure: ["Local file header: 50 4B 03 04",
                        "Central directory", "End of central directory: 50 4B 05 06"]),
        ProtocolInfo(name: "ELF",
            summary: "Executável/objeto em sistemas Unix/Linux.",
            structure: ["Magic: 7F 45 4C 46", "e_ident (classe/endianness)",
                        "Program headers", "Section headers"]),
        ProtocolInfo(name: "Mach-O",
            summary: "Executável em plataformas Apple (iOS/macOS).",
            structure: ["Magic: FE ED FA CF (64-bit)", "Header + load commands",
                        "Segmentos __TEXT, __DATA", "Pode ser 'fat' (multi-arquitetura)"]),
        ProtocolInfo(name: "TLS (handshake)",
            summary: "Protocolo de transporte seguro usado pelo HTTPS.",
            structure: ["ClientHello / ServerHello", "Troca de certificado",
                        "Troca de chave (ECDHE)", "Finished + registros de aplicação cifrados"]),
        ProtocolInfo(name: "HTTP",
            summary: "Protocolo de aplicação texto para a web.",
            structure: ["Linha de requisição: MÉTODO /caminho HTTP/1.1",
                        "Cabeçalhos: Chave: Valor", "Linha em branco", "Corpo opcional"]),
        ProtocolInfo(name: "NDEF (NFC)",
            summary: "Formato de dados de tags NFC.",
            structure: ["Mensagem = sequência de registros", "Cada registro: flags + tipo + payload",
                        "Tipos comuns: URI, Text, MIME"])
    ]
}
