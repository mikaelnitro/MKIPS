import SwiftUI

/// Escala tipográfica do MK FLIP.
///
/// UI usa a fonte do sistema (SF Pro) com pesos deliberados; o terminal e
/// qualquer saída técnica usam monoespaçada para alinhamento de colunas.
enum MKFont {
    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func title(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular)
    }

    static func label(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium)
    }

    static func caption(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium)
    }

    /// Monoespaçada — terminal, hex dumps, hashes.
    static func mono(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
