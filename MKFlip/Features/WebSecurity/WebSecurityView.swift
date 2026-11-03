import SwiftUI

/// Web Security — analisa TLS e cabeçalhos de segurança de um domínio
/// autorizado. Exige confirmação explícita de autorização antes de escanear.
struct WebSecurityView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var domain = ""
    @State private var authorized = false
    @State private var busy = false
    @State private var result: WebScanResult?

    var body: some View {
        ModuleScreen(title: "Web Security") {
            MKSectionHeader(title: "Domínio alvo")
            MKTextField(placeholder: "https://seudominio.com", text: $domain)

            Toggle(isOn: $authorized) {
                Text("Declaro que possuo ou tenho autorização para testar este domínio.")
                    .font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textSecondary)
            }
            .tint(MKTheme.Color.neon)

            MKButton(title: busy ? "Analisando…" : "Analisar", systemImage: "lock.shield") {
                scan()
            }
            .disabled(!authorized || domain.isEmpty || busy)
            .opacity(!authorized || domain.isEmpty ? 0.5 : 1)

            if busy { ProgressView().tint(MKTheme.Color.neon) }

            if let result { resultView(result) }
        }
    }

    @ViewBuilder
    private func resultView(_ r: WebScanResult) -> some View {
        if let error = r.error {
            MKCard {
                Label(error, systemImage: "xmark.octagon")
                    .font(MKFont.body(13)).foregroundStyle(MKTheme.Color.danger)
            }
        } else {
            MKCard(highlighted: true) {
                VStack(alignment: .leading, spacing: 6) {
                    MKKeyValueRow(key: "Status HTTP", value: r.statusCode.map(String.init) ?? "—")
                    if let server = r.server { MKKeyValueRow(key: "Servidor", value: server) }
                    if let s = r.certSubject { MKKeyValueRow(key: "Certificado", value: s) }
                    if let i = r.certIssuer { MKKeyValueRow(key: "Emissor", value: i) }
                    if let na = r.certNotAfter {
                        MKKeyValueRow(key: "Expira", value: Report.stamp.string(from: na),
                                      valueTint: na < Date() ? MKTheme.Color.danger : MKTheme.Color.textPrimary)
                    }
                }
            }

            MKSectionHeader(title: "Verificações de segurança")
            MKCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(r.findings) { f in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: f.ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(f.ok ? MKTheme.Color.neon : MKTheme.Color.warning)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(f.title).font(MKFont.label(13)).foregroundStyle(MKTheme.Color.textPrimary)
                                Text(f.detail).font(MKFont.caption()).foregroundStyle(MKTheme.Color.textSecondary)
                            }
                        }
                    }
                }
            }

            MKSectionHeader(title: "Relatório")
            MKCard {
                ReportResultView(report: r.asReport()) {
                    env.reportStore.add(r.asReport())
                    env.activityLog.log("WEB", "Relatório salvo: \(r.url)", severity: .success)
                }
            }
        }
    }

    private func scan() {
        busy = true; result = nil
        let scanner = WebSecurityScanner()
        env.activityLog.log("WEB", "Iniciando análise de \(domain)", severity: .info)
        Task {
            let r = await scanner.scan(domain)
            await MainActor.run {
                result = r; busy = false
                env.activityLog.log("WEB",
                                    r.error == nil ? "Análise concluída (\(r.findings.filter { !$0.ok }.count) alerta(s))"
                                                   : "Falha: \(r.error!)",
                                    severity: r.error == nil ? .success : .error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WebSecurityView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
