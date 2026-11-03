import SwiftUI

/// Botão primário/secundário do app, com feedback de toque.
struct MKButton: View {
    enum Kind { case primary, secondary, ghost }

    let title: String
    var systemImage: String? = nil
    var kind: Kind = .primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(MKFont.label(14))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(MKButtonStyle(kind: kind))
    }
}

private struct MKButtonStyle: ButtonStyle {
    let kind: MKButton.Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(
                RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadiusSmall, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadiusSmall, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary: MKTheme.Color.background
        case .secondary: MKTheme.Color.textPrimary
        case .ghost: MKTheme.Color.neon
        }
    }

    private var background: Color {
        switch kind {
        case .primary: MKTheme.Color.neon
        case .secondary: MKTheme.Color.surfaceElevated
        case .ghost: .clear
        }
    }

    private var border: Color {
        switch kind {
        case .primary: .clear
        case .secondary: MKTheme.Color.hairline
        case .ghost: MKTheme.Color.neon.opacity(0.5)
        }
    }
}

#Preview {
    ZStack {
        MKBackground()
        VStack(spacing: 12) {
            MKButton(title: "Executar", systemImage: "play.fill") {}
            MKButton(title: "Cancelar", kind: .secondary) {}
            MKButton(title: "Abrir terminal", systemImage: "terminal", kind: .ghost) {}
        }
        .padding()
    }
}
