import SwiftUI

/// Uma linha do terminal: `HH:mm:ss [FONTE] mensagem`, colorida por severidade.
struct TerminalLineView: View {
    let event: ActivityEvent

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(event.clock)
                .foregroundStyle(MKTheme.Color.textTertiary)
            Text(event.severity.glyph)
                .foregroundStyle(color)
            Text("[\(event.source)]")
                .foregroundStyle(MKTheme.Color.purple.opacity(0.9))
            Text(event.message)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(MKFont.mono(12))
        .textSelection(.enabled)
    }

    private var color: Color {
        switch event.severity {
        case .info: MKTheme.Color.textSecondary
        case .success: MKTheme.Color.neon
        case .warning: MKTheme.Color.warning
        case .error: MKTheme.Color.danger
        }
    }
}

#Preview {
    ZStack {
        MKBackground()
        VStack(alignment: .leading) {
            TerminalLineView(event: .init(source: "SYSTEM", message: "Boot OK", severity: .success))
            TerminalLineView(event: .init(source: "NFC", message: "Tag não compatível", severity: .warning))
            TerminalLineView(event: .init(source: "NET", message: "Falha de DNS", severity: .error))
        }
        .padding()
    }
}
