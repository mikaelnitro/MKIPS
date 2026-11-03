import SwiftUI

/// Ajustes do app. Na Fase 1 expõe informações de build e a política de
/// chaves de API (nunca embutidas no código-fonte).
struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MKTheme.Metric.spacingLarge) {
                VStack(alignment: .leading, spacing: 10) {
                    MKSectionHeader(title: "Sistema")
                    MKCard {
                        infoRow("Versão", "0.1.0 (Fase 1)")
                        Divider().overlay(MKTheme.Color.hairline)
                        infoRow("Plataforma", "iOS 18 · iPhone 16")
                        Divider().overlay(MKTheme.Color.hairline)
                        infoRow("Módulos online", "\(ModuleCatalog.onlineCount)/\(ModuleCatalog.all.count)")
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    MKSectionHeader(title: "Inteligência artificial")
                    MKCard {
                        Text("A MK AI opera **offline** até que uma API seja configurada. As chaves nunca são gravadas no código-fonte — serão lidas do Keychain na Fase 5.")
                            .font(MKFont.body())
                            .foregroundStyle(MKTheme.Color.textSecondary)
                    }
                }
            }
            .padding(MKTheme.Metric.spacing)
        }
        .background(MKBackground())
        .navigationTitle("Configurações")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).font(MKFont.body())
                .foregroundStyle(MKTheme.Color.textSecondary)
            Spacer()
            Text(value).font(MKFont.mono(13))
                .foregroundStyle(MKTheme.Color.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
