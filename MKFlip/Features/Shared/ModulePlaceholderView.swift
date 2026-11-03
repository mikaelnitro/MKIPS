import SwiftUI

/// Destino honesto para módulos ainda não implementados.
///
/// Não finge resultados: declara claramente a fase de entrega e lista as
/// capacidades planejadas. Satisfaz "nenhum botão sem função" (o cartão
/// navega e informa) sem violar "não inventar resultados".
struct ModulePlaceholderView: View {
    let module: ToolModule
    var capabilities: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MKTheme.Metric.spacingLarge) {
                header

                MKCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Módulo ainda não implementado", systemImage: "hammer")
                            .font(MKFont.label(14))
                            .foregroundStyle(MKTheme.Color.warning)
                        Text("Este módulo está planejado para a **Fase \(module.phase)**. A tela existe para que a navegação seja real; nenhuma análise falsa é exibida aqui.")
                            .font(MKFont.body())
                            .foregroundStyle(MKTheme.Color.textSecondary)
                    }
                }

                if !capabilities.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        MKSectionHeader(title: "Capacidades planejadas")
                        ForEach(capabilities, id: \.self) { cap in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 5))
                                    .foregroundStyle(MKTheme.Color.neon)
                                    .padding(.top, 6)
                                Text(cap)
                                    .font(MKFont.body())
                                    .foregroundStyle(MKTheme.Color.textPrimary)
                            }
                        }
                    }
                }
            }
            .padding(MKTheme.Metric.spacing)
        }
        .background(MKBackground())
        .navigationTitle(module.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: module.systemImage)
                .font(.system(size: 28))
                .foregroundStyle(module.state.tint)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(module.state.tint.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(module.name).font(MKFont.title())
                    .foregroundStyle(MKTheme.Color.textPrimary)
                Text(module.subtitle).font(MKFont.body(13))
                    .foregroundStyle(MKTheme.Color.textSecondary)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ModulePlaceholderView(
            module: ModuleCatalog.module(.nfcLab),
            capabilities: ["Leitura de tags NDEF", "Identificação de tecnologia", "Histórico de leituras"]
        )
    }
}
