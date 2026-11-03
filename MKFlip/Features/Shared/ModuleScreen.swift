import SwiftUI

/// Casca padrão de tela de módulo: fundo, título de navegação e um
/// `ScrollView` com padding consistente. Reduz repetição entre módulos.
struct ModuleScreen<Content: View>: View {
    let title: String
    var scrolls: Bool = true
    @ViewBuilder var content: Content

    var body: some View {
        Group {
            if scrolls {
                ScrollView {
                    VStack(alignment: .leading, spacing: MKTheme.Metric.spacingLarge) {
                        content
                    }
                    .padding(MKTheme.Metric.spacing)
                    .padding(.bottom, 40)
                }
            } else {
                VStack(alignment: .leading, spacing: MKTheme.Metric.spacingLarge) {
                    content
                }
                .padding(MKTheme.Metric.spacing)
            }
        }
        .background(MKBackground())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Campo de entrada com visual do app (fundo escuro, mono opcional).
struct MKTextField: View {
    let placeholder: String
    @Binding var text: String
    var mono: Bool = false
    var autocap: TextInputAutocapitalization = .never

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(mono ? MKFont.mono(13) : MKFont.body())
            .foregroundStyle(MKTheme.Color.textPrimary)
            .textInputAutocapitalization(autocap)
            .autocorrectionDisabled()
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadiusSmall, style: .continuous)
                    .fill(MKTheme.Color.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadiusSmall, style: .continuous)
                    .strokeBorder(MKTheme.Color.hairline, lineWidth: 1)
            )
    }
}

/// Linha chave→valor monoespaçada, com cópia ao toque longo.
struct MKKeyValueRow: View {
    let key: String
    let value: String
    var valueTint: Color = MKTheme.Color.textPrimary

    var body: some View {
        HStack(alignment: .top) {
            Text(key).font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textSecondary)
            Spacer(minLength: 12)
            Text(value).font(MKFont.mono(12)).foregroundStyle(valueTint)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .padding(.vertical, 3)
    }
}
