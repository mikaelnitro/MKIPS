import SwiftUI

/// Password Lab — auditoria local de força de senha. Nenhuma senha sai do
/// dispositivo nem é registrada no histórico.
struct PasswordLabView: View {
    @State private var password = ""
    @State private var reveal = false
    @State private var audit: PasswordAudit?

    var body: some View {
        ModuleScreen(title: "Password Lab") {
            MKSectionHeader(title: "Senha para auditar")
            MKCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Group {
                            if reveal {
                                TextField("Digite a senha…", text: $password)
                            } else {
                                SecureField("Digite a senha…", text: $password)
                            }
                        }
                        .font(MKFont.mono(14))
                        .foregroundStyle(MKTheme.Color.textPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        Button { reveal.toggle() } label: {
                            Image(systemName: reveal ? "eye.slash" : "eye")
                                .foregroundStyle(MKTheme.Color.textSecondary)
                        }
                    }
                    Text("Processada apenas no dispositivo. Não é salva nem enviada.")
                        .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
                }
            }

            MKButton(title: "Auditar", systemImage: "checkmark.shield") {
                audit = PasswordAnalyzer.audit(password)
            }

            if let audit { resultView(audit) }
        }
    }

    @ViewBuilder
    private func resultView(_ a: PasswordAudit) -> some View {
        let tint = strengthColor(a.strength)
        MKCard(highlighted: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(a.strength.rawValue).font(MKFont.title(18)).foregroundStyle(tint)
                    Spacer()
                    Text("\(Int(a.entropyBits)) bits").font(MKFont.mono(14)).foregroundStyle(tint)
                }
                ProgressView(value: min(a.entropyBits, 128), total: 128)
                    .tint(tint)
                MKKeyValueRow(key: "Comprimento", value: "\(a.length)")
                MKKeyValueRow(key: "Alfabeto estimado", value: "\(a.poolSize) símbolos")
                MKKeyValueRow(key: "Entropia", value: String(format: "%.1f bits", a.entropyBits))
            }
        }

        if !a.patterns.isEmpty {
            section("Fraquezas detectadas", a.patterns, tint: MKTheme.Color.danger, icon: "exclamationmark.triangle")
        }
        section("Recomendações", a.recommendations, tint: MKTheme.Color.neon, icon: "lightbulb")
    }

    private func section(_ title: String, _ items: [String], tint: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MKSectionHeader(title: title)
            MKCard {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(tint)
                            Text(item).font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private func strengthColor(_ s: PasswordAudit.Strength) -> Color {
        switch s {
        case .veryWeak, .weak: MKTheme.Color.danger
        case .moderate: MKTheme.Color.warning
        case .strong, .veryStrong: MKTheme.Color.neon
        }
    }
}

#Preview {
    NavigationStack { PasswordLabView() }
}
