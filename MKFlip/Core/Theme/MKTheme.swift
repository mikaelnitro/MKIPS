import SwiftUI

/// Identidade visual do MK FLIP.
///
/// Paleta: preto profundo de fundo, roxo escuro como secundária, verde neon
/// para indicadores de atividade. Centralizar aqui evita cores soltas
/// espalhadas pelas views e mantém a consistência entre módulos.
enum MKTheme {

    // MARK: - Cores

    enum Color {
        /// Fundo base — preto profundo, levemente dessaturado para não "vibrar" em OLED.
        static let background = SwiftUI.Color(hex: 0x050507)
        /// Fundo elevado (cartões, barras).
        static let surface = SwiftUI.Color(hex: 0x0D0B14)
        /// Superfície mais clara para estados de destaque/hover.
        static let surfaceElevated = SwiftUI.Color(hex: 0x16121F)

        /// Roxo escuro — cor secundária / acento estrutural.
        static let purple = SwiftUI.Color(hex: 0x6B21A8)
        static let purpleDeep = SwiftUI.Color(hex: 0x2A0E45)

        /// Verde neon — reservado para atividade/estado "vivo". Usar com parcimônia.
        static let neon = SwiftUI.Color(hex: 0x2BFF88)
        static let neonDim = SwiftUI.Color(hex: 0x1C9E58)

        /// Alertas.
        static let warning = SwiftUI.Color(hex: 0xFFB020)
        static let danger = SwiftUI.Color(hex: 0xFF4D5E)

        // Texto
        static let textPrimary = SwiftUI.Color(hex: 0xF2F0F7)
        static let textSecondary = SwiftUI.Color(hex: 0x9A94AD)
        static let textTertiary = SwiftUI.Color(hex: 0x5C586B)

        /// Bordas sutis sobre superfícies escuras.
        static let hairline = SwiftUI.Color.white.opacity(0.06)
    }

    // MARK: - Métricas

    enum Metric {
        static let cornerRadius: CGFloat = 16
        static let cornerRadiusSmall: CGFloat = 10
        static let spacing: CGFloat = 16
        static let spacingSmall: CGFloat = 8
        static let spacingLarge: CGFloat = 24
        static let hairline: CGFloat = 1
        static let cardPadding: CGFloat = 16
    }

    // MARK: - Gradientes

    /// Gradiente de acento usado em bordas/realces de cartões ativos.
    static let accentGradient = LinearGradient(
        colors: [Color.purple.opacity(0.9), Color.neon.opacity(0.35)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    /// Inicializa a partir de um literal hexadecimal 0xRRGGBB.
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
