import SwiftUI

/// Fundo padrão do app: preto profundo com um brilho roxo discreto no topo.
/// Tecnológico, sem exageros — coerente com a identidade "central profissional".
struct MKBackground: View {
    var body: some View {
        ZStack {
            MKTheme.Color.background
                .ignoresSafeArea()

            RadialGradient(
                colors: [MKTheme.Color.purpleDeep.opacity(0.55), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
            .blendMode(.screen)
        }
    }
}

#Preview {
    MKBackground()
}
