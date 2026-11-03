import SwiftUI
import UniformTypeIdentifiers

/// Digital Forensics — importa um arquivo e o analisa sem alterá-lo.
struct ForensicsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var importing = false
    @State private var analysis: FileAnalysis?
    @State private var errorMessage: String?
    @State private var tab: Tab = .overview

    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Resumo", hashes = "Hashes", hex = "Hex", strings = "Strings"
        var id: String { rawValue }
    }

    var body: some View {
        ModuleScreen(title: "Digital Forensics") {
            MKButton(title: "Importar arquivo", systemImage: "square.and.arrow.down") {
                importing = true
            }
            Text("O arquivo original é preservado — a análise ocorre sobre uma cópia em memória.")
                .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)

            if let errorMessage {
                Text(errorMessage).font(MKFont.body(13)).foregroundStyle(MKTheme.Color.danger)
            }

            if let analysis {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)

                switch tab {
                case .overview: overview(analysis)
                case .hashes:   hashes(analysis)
                case .hex:      hexView(analysis)
                case .strings:  stringsView(analysis)
                }

                MKSectionHeader(title: "Relatório")
                MKCard {
                    ReportResultView(report: analysis.asReport()) {
                        env.reportStore.add(analysis.asReport())
                        env.activityLog.log("FORENSICS", "Relatório salvo: \(analysis.name)", severity: .success)
                    }
                }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
            handleImport(result)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        errorMessage = nil
        do {
            guard let url = try result.get().first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let a = ForensicsAnalyzer.analyze(data: data, name: url.lastPathComponent)
            analysis = a
            env.activityLog.log("FORENSICS",
                                "Analisado \(a.name) · \(a.byteCount)B · \(a.detectedType?.name ?? "tipo desconhecido")",
                                severity: a.declaredVsDetectedMismatch ? .warning : .success)
        } catch {
            errorMessage = "Falha ao ler o arquivo: \(error.localizedDescription)"
        }
    }

    // MARK: Abas

    private func overview(_ a: FileAnalysis) -> some View {
        MKCard {
            VStack(alignment: .leading, spacing: 4) {
                MKKeyValueRow(key: "Nome", value: a.name)
                MKKeyValueRow(key: "Extensão", value: a.fileExtension.isEmpty ? "—" : ".\(a.fileExtension)")
                MKKeyValueRow(key: "Tamanho", value: "\(a.byteCount) bytes")
                MKKeyValueRow(key: "Tipo detectado",
                              value: a.detectedType?.name ?? "desconhecido",
                              valueTint: a.detectedType == nil ? MKTheme.Color.textTertiary : MKTheme.Color.neon)
                if let t = a.detectedType { MKKeyValueRow(key: "MIME", value: t.mime) }
                MKKeyValueRow(key: "Entropia", value: String(format: "%.2f bits/byte", a.entropy),
                              valueTint: a.entropy > 7.5 ? MKTheme.Color.warning : MKTheme.Color.textPrimary)
                if a.declaredVsDetectedMismatch {
                    Divider().overlay(MKTheme.Color.hairline)
                    Label("Extensão incompatível com o conteúdo", systemImage: "exclamationmark.triangle")
                        .font(MKFont.label(13)).foregroundStyle(MKTheme.Color.danger)
                }
                if a.entropy > 7.5 {
                    Text("Entropia alta sugere dados comprimidos ou cifrados.")
                        .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
                }
            }
        }
    }

    private func hashes(_ a: FileAnalysis) -> some View {
        MKCard {
            VStack(alignment: .leading, spacing: 10) {
                hashRow("MD5", a.md5, legacy: true)
                hashRow("SHA-1", a.sha1, legacy: true)
                hashRow("SHA-256", a.sha256, legacy: false)
            }
        }
    }

    private func hashRow(_ name: String, _ value: String, legacy: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name).font(MKFont.label(12)).foregroundStyle(MKTheme.Color.neon)
                if legacy { Text("legado").font(MKFont.caption()).foregroundStyle(MKTheme.Color.warning) }
            }
            Text(value).font(MKFont.mono(11)).foregroundStyle(MKTheme.Color.textPrimary).textSelection(.enabled)
        }
    }

    private func hexView(_ a: FileAnalysis) -> some View {
        MKCard {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(a.hexLines.prefix(128).enumerated()), id: \.offset) { _, line in
                    Text(line).font(MKFont.mono(10)).foregroundStyle(MKTheme.Color.textSecondary)
                }
                if a.hexTruncated {
                    Text("… (exibindo os primeiros 4 KB)")
                        .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
                }
            }
        }
    }

    private func stringsView(_ a: FileAnalysis) -> some View {
        MKCard {
            VStack(alignment: .leading, spacing: 4) {
                if a.strings.isEmpty {
                    Text("Nenhuma string imprimível ≥ 4 caracteres.")
                        .font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textTertiary)
                }
                ForEach(Array(a.strings.prefix(120).enumerated()), id: \.offset) { _, s in
                    Text(s).font(MKFont.mono(11))
                        .foregroundStyle(a.interestingStrings.contains(s) ? MKTheme.Color.neon : MKTheme.Color.textSecondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForensicsView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
