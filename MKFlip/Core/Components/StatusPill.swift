import SwiftUI

/// Indicador compacto de estado, com ponto colorido + rótulo em caixa alta.
/// Usado para estado de módulo e status da IA.
struct StatusPill: View {
    let text: String
    let tint: Color
    var pulsing: Bool = false

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
                .shadow(color: tint.opacity(0.8), radius: pulse ? 5 : 2)
                .opacity(pulsing ? (pulse ? 1.0 : 0.4) : 1.0)
                .animation(
                    pulsing ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true) : .default,
                    value: pulse
                )

            Text(text)
                .font(MKFont.caption())
                .tracking(0.8)
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(tint.opacity(0.12))
        )
        .overlay(
            Capsule().stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .onAppear { if pulsing { pulse = true } }
    }
}

#Preview {
    ZStack {
        MKBackground()
        VStack(spacing: 12) {
            StatusPill(text: "ONLINE", tint: MKTheme.Color.neon, pulsing: true)
            StatusPill(text: "CONDICIONAL", tint: MKTheme.Color.warning)
            StatusPill(text: "EM BREVE", tint: MKTheme.Color.textTertiary)
        }
    }
}
