import SwiftUI

/// Cabeçalho de seção: título + ação opcional à direita.
struct MKSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(MKFont.label(13))
                .tracking(1.2)
                .foregroundStyle(MKTheme.Color.textSecondary)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(MKFont.caption())
                    .foregroundStyle(MKTheme.Color.neon)
            }
        }
    }
}

#Preview {
    ZStack {
        MKBackground()
        MKSectionHeader(title: "Módulos", actionTitle: "Ver tudo") {}
            .padding()
    }
}
