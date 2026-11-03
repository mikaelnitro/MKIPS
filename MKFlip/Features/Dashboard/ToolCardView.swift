import SwiftUI

/// Cartão de uma ferramenta no dashboard: ícone, nome, descrição, estado e
/// ação de abrir. Toda a área é tocável.
struct ToolCardView: View {
    let module: ToolModule
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MKCard(highlighted: module.state == .online) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: module.systemImage)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(module.state.tint)
                            .frame(width: 42, height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(module.state.tint.opacity(0.12))
                            )
                        Spacer()
                        StatusPill(text: module.state.label,
                                   tint: module.state.tint,
                                   pulsing: module.state == .online)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.name)
                            .font(MKFont.title(17))
                            .foregroundStyle(MKTheme.Color.textPrimary)
                        Text(module.subtitle)
                            .font(MKFont.body(13))
                            .foregroundStyle(MKTheme.Color.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 4) {
                        Text("Abrir")
                        Image(systemName: "arrow.right")
                    }
                    .font(MKFont.caption())
                    .foregroundStyle(MKTheme.Color.neon)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        MKBackground()
        ToolCardView(module: ModuleCatalog.module(.cryptography)) {}
            .padding()
    }
}
