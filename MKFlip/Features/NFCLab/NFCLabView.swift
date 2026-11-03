import SwiftUI

/// NFC Lab — leitura de tags NFC compatíveis via Core NFC. Informa claramente
/// quando uma tag não é compatível e não realiza clonagem.
struct NFCLabView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var reader = NFCReader()

    var body: some View {
        ModuleScreen(title: "NFC Lab") {
            if !reader.isAvailable {
                MKCard {
                    Label("NFC indisponível neste dispositivo/ambiente.", systemImage: "wave.3.right.circle")
                        .font(MKFont.body(14)).foregroundStyle(MKTheme.Color.warning)
                }
            }

            MKButton(title: "Ler tag NFC", systemImage: "wave.3.right") {
                reader.beginScan()
                env.activityLog.log("NFC", "Sessão de leitura iniciada", severity: .info)
            }
            .disabled(!reader.isAvailable)
            .opacity(reader.isAvailable ? 1 : 0.5)

            if !reader.statusMessage.isEmpty {
                Text(reader.statusMessage).font(MKFont.caption())
                    .foregroundStyle(MKTheme.Color.textSecondary)
            }

            MKCard {
                Text("O MK FLIP lê o identificador e registros NDEF de tags compatíveis. O iPhone não lê qualquer cartão; cartões de pagamento e credenciais de acesso não são suportados nem clonados.")
                    .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
            }

            if !reader.readings.isEmpty {
                MKSectionHeader(title: "Histórico de leituras")
                ForEach(reader.readings) { reading in
                    readingCard(reading)
                }
            }
        }
    }

    private func readingCard(_ r: NFCReading) -> some View {
        MKCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(r.technology).font(MKFont.label(13)).foregroundStyle(MKTheme.Color.neon)
                    Spacer()
                    Text(r.timestamp, style: .time).font(MKFont.caption())
                        .foregroundStyle(MKTheme.Color.textTertiary)
                }
                MKKeyValueRow(key: "UID", value: r.identifier)
                ForEach(r.extra.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                    MKKeyValueRow(key: k, value: v)
                }
                if !r.ndefRecords.isEmpty {
                    Divider().overlay(MKTheme.Color.hairline)
                    Text("NDEF").font(MKFont.caption()).foregroundStyle(MKTheme.Color.purple)
                    ForEach(Array(r.ndefRecords.enumerated()), id: \.offset) { _, rec in
                        Text(rec).font(MKFont.mono(11)).foregroundStyle(MKTheme.Color.textPrimary)
                            .textSelection(.enabled)
                    }
                } else {
                    Text("Sem registros NDEF legíveis.").font(MKFont.caption())
                        .foregroundStyle(MKTheme.Color.textTertiary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NFCLabView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
