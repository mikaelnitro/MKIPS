import SwiftUI

/// Network Intelligence — informações da conexão, consulta DNS e verificação
/// de disponibilidade de serviços em hosts informados pelo usuário.
struct NetworkView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var monitor = ConnectionMonitor()
    private let tools = NetworkTools()

    @State private var host = ""
    @State private var portText = "443"
    @State private var dns: NetworkTools.DNSResult?
    @State private var portStatus: NetworkTools.PortStatus?
    @State private var busy = false

    var body: some View {
        ModuleScreen(title: "Network Intelligence") {
            connectionCard

            MKSectionHeader(title: "Diagnóstico de host")
            MKTextField(placeholder: "exemplo.com", text: $host)
            HStack(spacing: 10) {
                MKButton(title: "Resolver DNS", systemImage: "arrow.triangle.branch") {
                    runDNS()
                }
                HStack {
                    Text("Porta").font(MKFont.caption()).foregroundStyle(MKTheme.Color.textSecondary)
                    TextField("443", text: $portText)
                        .font(MKFont.mono(13)).foregroundStyle(MKTheme.Color.textPrimary)
                        .keyboardType(.numberPad).frame(width: 56)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(MKTheme.Color.background))
                }
            }
            MKButton(title: "Verificar porta (TCP)", systemImage: "bolt.horizontal", kind: .secondary) {
                runPortCheck()
            }

            if busy { ProgressView().tint(MKTheme.Color.neon) }

            if let dns { dnsCard(dns) }
            if let portStatus { portCard(portStatus) }

            Text("Diagnósticos pontuais sobre hosts que você informar. O iOS não expõe varredura ampla de rede.")
                .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
        }
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
    }

    private var connectionCard: some View {
        MKCard(highlighted: true) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("CONEXÃO ATUAL").font(MKFont.caption()).tracking(1)
                        .foregroundStyle(MKTheme.Color.textTertiary)
                    Spacer()
                    StatusPill(text: monitor.isConnected ? "ONLINE" : "OFFLINE",
                               tint: monitor.isConnected ? MKTheme.Color.neon : MKTheme.Color.danger,
                               pulsing: monitor.isConnected)
                }
                MKKeyValueRow(key: "Interface", value: monitor.interface)
                MKKeyValueRow(key: "Conexão limitada", value: monitor.isExpensive ? "Sim" : "Não")
            }
        }
    }

    private func dnsCard(_ r: NetworkTools.DNSResult) -> some View {
        MKCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("DNS · \(r.host)").font(MKFont.label(13)).foregroundStyle(MKTheme.Color.neon)
                if let error = r.error, r.addresses.isEmpty {
                    Text(error).font(MKFont.body(13)).foregroundStyle(MKTheme.Color.danger)
                } else {
                    ForEach(r.addresses, id: \.self) { addr in
                        Text(addr).font(MKFont.mono(12)).foregroundStyle(MKTheme.Color.textPrimary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    private func portCard(_ s: NetworkTools.PortStatus) -> some View {
        let tint: Color = s == .open ? MKTheme.Color.neon : (s == .timeout ? MKTheme.Color.warning : MKTheme.Color.danger)
        return MKCard {
            HStack {
                Text("Porta \(portText)").font(MKFont.label(13)).foregroundStyle(MKTheme.Color.textSecondary)
                Spacer()
                StatusPill(text: s.rawValue.uppercased(), tint: tint)
            }
        }
    }

    private func runDNS() {
        busy = true; dns = nil
        Task {
            let result = await tools.resolve(host)
            await MainActor.run {
                dns = result; busy = false
                env.activityLog.log("NET", "DNS \(result.host): \(result.addresses.count) endereço(s)",
                                    severity: result.addresses.isEmpty ? .warning : .success)
            }
        }
    }

    private func runPortCheck() {
        guard let port = UInt16(portText) else { return }
        busy = true; portStatus = nil
        Task {
            let status = await tools.checkPort(host, port: port)
            await MainActor.run {
                portStatus = status; busy = false
                env.activityLog.log("NET", "Porta \(port) em \(host): \(status.rawValue)",
                                    severity: status == .open ? .success : .warning)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NetworkView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
