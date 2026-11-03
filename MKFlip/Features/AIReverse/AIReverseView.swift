import SwiftUI
import UniformTypeIdentifiers

/// AI Reverse — laboratório de análise técnica organizado em abas. Toda análise
/// é estática e local; não há exploração automática de dispositivos de terceiros.
struct AIReverseView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var tab: Tab = .analyze

    enum Tab: String, CaseIterable, Identifiable {
        case analyze = "Arquivo", compare = "Comparar", protocols = "Protocolos"
        var id: String { rawValue }
    }

    var body: some View {
        ModuleScreen(title: "AI Reverse") {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)

            switch tab {
            case .analyze:   AnalyzeTab(log: env.activityLog)
            case .compare:   CompareTab(log: env.activityLog)
            case .protocols: ProtocolsTab()
            }
        }
    }
}

// MARK: - Analisar arquivo

private struct AnalyzeTab: View {
    let log: ActivityLog
    @State private var importing = false
    @State private var analysis: FileAnalysis?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MKButton(title: "Importar arquivo", systemImage: "square.and.arrow.down") { importing = true }

            if let a = analysis {
                MKCard {
                    VStack(alignment: .leading, spacing: 4) {
                        MKKeyValueRow(key: "Arquivo", value: a.name)
                        MKKeyValueRow(key: "Tipo real", value: a.detectedType?.name ?? "desconhecido",
                                      valueTint: MKTheme.Color.neon)
                        MKKeyValueRow(key: "Tamanho", value: "\(a.byteCount) bytes")
                        MKKeyValueRow(key: "Entropia", value: String(format: "%.2f bits/byte", a.entropy),
                                      valueTint: a.entropy > 7.5 ? MKTheme.Color.warning : MKTheme.Color.textPrimary)
                        if a.declaredVsDetectedMismatch {
                            Label("Extensão incompatível com o conteúdo",
                                  systemImage: "exclamationmark.triangle")
                                .font(MKFont.caption()).foregroundStyle(MKTheme.Color.danger)
                        }
                    }
                }
                MKSectionHeader(title: "Strings de interesse")
                MKCard {
                    VStack(alignment: .leading, spacing: 3) {
                        if a.interestingStrings.isEmpty {
                            Text("Nenhuma.").font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textTertiary)
                        }
                        ForEach(Array(a.interestingStrings.prefix(40).enumerated()), id: \.offset) { _, s in
                            Text(s).font(MKFont.mono(11)).foregroundStyle(MKTheme.Color.neon)
                                .textSelection(.enabled)
                        }
                    }
                }
                MKSectionHeader(title: "Hex (início)")
                MKCard {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(a.hexLines.prefix(48).enumerated()), id: \.offset) { _, line in
                            Text(line).font(MKFont.mono(10)).foregroundStyle(MKTheme.Color.textSecondary)
                        }
                    }
                }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.data]) { result in
            if let url = try? result.get() {
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    analysis = ForensicsAnalyzer.analyze(data: data, name: url.lastPathComponent)
                    log.log("REVERSE", "Arquivo analisado: \(url.lastPathComponent)", severity: .success)
                }
            }
        }
    }
}

// MARK: - Comparar

private struct CompareTab: View {
    let log: ActivityLog
    @State private var dataA: Data?
    @State private var dataB: Data?
    @State private var nameA = "—"
    @State private var nameB = "—"
    @State private var importingA = false
    @State private var importingB = false
    @State private var result: FileComparison?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                MKButton(title: "Arquivo A", systemImage: "doc", kind: .secondary) { importingA = true }
                MKButton(title: "Arquivo B", systemImage: "doc", kind: .secondary) { importingB = true }
            }
            MKCard {
                VStack(alignment: .leading, spacing: 2) {
                    MKKeyValueRow(key: "A", value: nameA)
                    MKKeyValueRow(key: "B", value: nameB)
                }
            }
            MKButton(title: "Comparar", systemImage: "arrow.left.arrow.right") {
                if let a = dataA, let b = dataB {
                    result = FileComparator.compare(a, b)
                    log.log("REVERSE", "Comparação: \(result!.identical ? "idênticos" : "diferentes")",
                            severity: .info)
                }
            }
            .disabled(dataA == nil || dataB == nil)
            .opacity(dataA == nil || dataB == nil ? 0.5 : 1)

            if let r = result {
                MKCard(highlighted: true) {
                    VStack(alignment: .leading, spacing: 4) {
                        MKKeyValueRow(key: "Idênticos", value: r.identical ? "Sim" : "Não",
                                      valueTint: r.identical ? MKTheme.Color.neon : MKTheme.Color.warning)
                        MKKeyValueRow(key: "Tamanho A", value: "\(r.sizeA) B")
                        MKKeyValueRow(key: "Tamanho B", value: "\(r.sizeB) B")
                        MKKeyValueRow(key: "Bytes iniciais iguais", value: "\(r.sameLeadingBytes)")
                        if let off = r.firstDiffOffset {
                            MKKeyValueRow(key: "1ª diferença", value: String(format: "offset 0x%X", off))
                        }
                    }
                }
            }
        }
        .fileImporter(isPresented: $importingA, allowedContentTypes: [.data]) { res in
            load(res) { dataA = $0; nameA = $1 }
        }
        .fileImporter(isPresented: $importingB, allowedContentTypes: [.data]) { res in
            load(res) { dataB = $0; nameB = $1 }
        }
    }

    private func load(_ res: Result<URL, Error>, assign: (Data, String) -> Void) {
        if let url = try? res.get() {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let data = try? Data(contentsOf: url) { assign(data, url.lastPathComponent) }
        }
    }
}

// MARK: - Protocolos

private struct ProtocolsTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(ProtocolLibrary.all) { proto in
                MKCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(proto.name).font(MKFont.title(16)).foregroundStyle(MKTheme.Color.neon)
                        Text(proto.summary).font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textSecondary)
                        ForEach(proto.structure, id: \.self) { line in
                            HStack(alignment: .top, spacing: 6) {
                                Text("▸").foregroundStyle(MKTheme.Color.purple)
                                Text(line).font(MKFont.mono(11)).foregroundStyle(MKTheme.Color.textPrimary)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AIReverseView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
