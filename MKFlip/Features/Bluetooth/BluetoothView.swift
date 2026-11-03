import SwiftUI

/// Bluetooth Intelligence — inventário de dispositivos BLE próximos.
/// Somente observação de anúncios públicos; sem conexão ou exploração.
struct BluetoothView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var scanner = BluetoothScanner()

    var body: some View {
        ModuleScreen(title: "Bluetooth Intelligence") {
            MKCard(highlighted: scanner.isScanning) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scanner.stateMessage).font(MKFont.body(13))
                            .foregroundStyle(MKTheme.Color.textPrimary)
                        Text("\(scanner.devices.count) dispositivo(s)").font(MKFont.caption())
                            .foregroundStyle(MKTheme.Color.textTertiary)
                    }
                    Spacer()
                    StatusPill(text: scanner.isScanning ? "ESCANEANDO" : "PARADO",
                               tint: scanner.isScanning ? MKTheme.Color.neon : MKTheme.Color.textTertiary,
                               pulsing: scanner.isScanning)
                }
            }

            MKButton(title: scanner.isScanning ? "Parar varredura" : "Iniciar varredura",
                     systemImage: scanner.isScanning ? "stop.fill" : "antenna.radiowaves.left.and.right") {
                scanner.toggleScan()
                env.activityLog.log("BLE", scanner.isScanning ? "Varredura iniciada" : "Varredura parada",
                                    severity: .info)
            }
            .disabled(!scanner.poweredOn)
            .opacity(scanner.poweredOn ? 1 : 0.5)

            Text("Somente observação de anúncios públicos. O app não conecta, não pareia e não explora dispositivos.")
                .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)

            ForEach(scanner.devices) { device in
                deviceCard(device)
            }
        }
        .onAppear { scanner.configure() }
        .onDisappear { if scanner.isScanning { scanner.toggleScan() } }
    }

    private func deviceCard(_ d: BLEDevice) -> some View {
        MKCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(d.name).font(MKFont.label(14)).foregroundStyle(MKTheme.Color.textPrimary)
                    Spacer()
                    signalIcon(d.signalBars)
                    Text("\(d.rssi) dBm").font(MKFont.mono(11)).foregroundStyle(MKTheme.Color.textSecondary)
                }
                MKKeyValueRow(key: "ID", value: d.id.uuidString)
                if !d.serviceUUIDs.isEmpty {
                    MKKeyValueRow(key: "Serviços", value: d.serviceUUIDs.joined(separator: ", "))
                }
                if let m = d.manufacturer { MKKeyValueRow(key: "Fabricante", value: m) }
            }
        }
    }

    private func signalIcon(_ bars: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < bars ? MKTheme.Color.neon : MKTheme.Color.textTertiary.opacity(0.3))
                    .frame(width: 3, height: CGFloat(5 + i * 3))
            }
        }
    }
}

#Preview {
    NavigationStack {
        BluetoothView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
