import SwiftUI

/// Contêiner de cartão padrão: superfície elevada, cantos arredondados e
/// borda em fio de cabelo. Base visual de todo o app.
struct MKCard<Content: View>: View {
    var highlighted: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(MKTheme.Metric.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadius, style: .continuous)
                    .fill(MKTheme.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadius, style: .continuous)
                    .strokeBorder(
                        highlighted ? AnyShapeStyle(MKTheme.accentGradient)
                                    : AnyShapeStyle(MKTheme.Color.hairline),
                        lineWidth: 1
                    )
            )
    }
}

#Preview {
    ZStack {
        MKBackground()
        VStack {
            MKCard { Text("Cartão padrão").foregroundStyle(MKTheme.Color.textPrimary) }
            MKCard(highlighted: true) { Text("Destacado").foregroundStyle(MKTheme.Color.textPrimary) }
        }
        .padding()
    }
}
