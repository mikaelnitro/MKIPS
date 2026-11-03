import SwiftUI

/// OSINT Intelligence — investigação de dados públicos: registros DNS,
/// análise de URL/domínio e organização de evidências em um relatório.
struct OSINTView: View {
    @Environment(AppEnvironment.self) private var env
    private let doh = DoHClient()

    @State private var target = ""
    @State private var records: [DoHClient.Record] = []
    @State private var urlAnalysis: URLAnalysis?
    @State private var busy = false
    @State private var evidence: [String] = []

    var body: some View {
        ModuleScreen(title: "OSINT Intelligence") {
            MKSectionHeader(title: "Alvo (domínio ou URL)")
            MKTextField(placeholder: "exemplo.com", text: $target)
            HStack(spacing: 10) {
                MKButton(title: "Consultar DNS", systemImage: "server.rack") { runDNS() }
                MKButton(title: "Analisar URL", systemImage: "link", kind: .secondary) { runURL() }
            }

            if busy { ProgressView().tint(MKTheme.Color.neon) }

            if let urlAnalysis { urlCard(urlAnalysis) }
            if !records.isEmpty { dnsCard() }
            evidenceSection
        }
    }

    private func urlCard(_ a: URLAnalysis) -> some View {
        let tint: Color = a.riskLevel == .high ? MKTheme.Color.danger
                        : (a.riskLevel == .medium ? MKTheme.Color.warning : MKTheme.Color.neon)
        return MKCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Análise de URL").font(MKFont.label(13)).foregroundStyle(MKTheme.Color.neon)
                    Spacer()
                    StatusPill(text: "RISCO \(a.riskLevel.rawValue.uppercased())", tint: tint)
                }
                if let host = a.host { MKKeyValueRow(key: "Host", value: host) }
                ForEach(a.riskSignals, id: \.self) { s in
                    Text("• \(s)").font(MKFont.body(12)).foregroundStyle(MKTheme.Color.textSecondary)
                }
                if a.riskSignals.isEmpty {
                    Text("Sem sinais óbvios de risco.").font(MKFont.caption())
                        .foregroundStyle(MKTheme.Color.textTertiary)
                }
                MKButton(title: "Adicionar à evidência", systemImage: "plus", kind: .ghost) {
                    addEvidence("URL \(a.normalized) · risco \(a.riskLevel.rawValue)")
                }
            }
        }
    }

    private func dnsCard() -> some View {
        MKCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Registros DNS").font(MKFont.label(13)).foregroundStyle(MKTheme.Color.neon)
                ForEach(records) { r in
                    HStack(alignment: .top, spacing: 8) {
                        Text(r.type).font(MKFont.mono(11, weight: .bold))
                            .foregroundStyle(MKTheme.Color.purple).frame(width: 46, alignment: .leading)
                        Text(r.value).font(MKFont.mono(11)).foregroundStyle(MKTheme.Color.textPrimary)
                            .textSelection(.enabled)
                    }
                }
                MKButton(title: "Adicionar DNS à evidência", systemImage: "plus", kind: .ghost) {
                    for r in records { addEvidence("DNS \(r.type): \(r.value)") }
                }
            }
        }
    }

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MKSectionHeader(title: "Evidências coletadas")
            if evidence.isEmpty {
                Text("Nenhuma evidência adicionada ainda.")
                    .font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textTertiary)
            } else {
                MKCard {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(evidence.enumerated()), id: \.offset) { i, e in
                            Text("\(i + 1). \(e)").font(MKFont.mono(11))
                                .foregroundStyle(MKTheme.Color.textSecondary)
                        }
                    }
                }
                MKCard {
                    ReportResultView(report: buildReport()) {
                        env.reportStore.add(buildReport())
                        env.activityLog.log("OSINT", "Relatório salvo: \(target)", severity: .success)
                    }
                }
            }
        }
    }

    private func buildReport() -> Report {
        Report(tool: "OSINT Intelligence", title: "Investigação de \(target)", subject: target,
               sections: [.init(heading: "Evidências", lines: evidence.isEmpty ? ["(vazio)"] : evidence)])
    }

    private func addEvidence(_ item: String) {
        if !evidence.contains(item) { evidence.append(item) }
    }

    private func runDNS() {
        busy = true; records = []
        Task {
            let r = await doh.query(target)
            await MainActor.run {
                records = r; busy = false
                env.activityLog.log("OSINT", "DNS \(target): \(r.count) registro(s)",
                                    severity: r.isEmpty ? .warning : .success)
            }
        }
    }

    private func runURL() {
        urlAnalysis = URLAnalyzer.analyze(target)
        env.activityLog.log("OSINT", "URL analisada: risco \(urlAnalysis?.riskLevel.rawValue ?? "?")", severity: .info)
    }
}

#Preview {
    NavigationStack {
        OSINTView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
