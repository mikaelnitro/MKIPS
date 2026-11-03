import SwiftUI

/// Painel de terminal somente-leitura que reflete o `ActivityLog`.
/// Rola automaticamente para a linha mais recente. O console interativo
/// (entrada de comandos) chega na Fase 2 reutilizando este painel.
struct TerminalPanel: View {
    let events: [ActivityEvent]
    var maxHeight: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(MKTheme.Color.hairline)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        if events.isEmpty {
                            Text("— sem atividade —")
                                .font(MKFont.mono(12))
                                .foregroundStyle(MKTheme.Color.textTertiary)
                                .padding(.vertical, 6)
                        }
                        ForEach(events) { event in
                            TerminalLineView(event: event).id(event.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                }
                .frame(maxHeight: maxHeight)
                .onChange(of: events.last?.id) { _, last in
                    guard let last else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadius, style: .continuous)
                .fill(Color.black)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadius, style: .continuous)
                .strokeBorder(MKTheme.Color.neon.opacity(0.18), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 11))
                .foregroundStyle(MKTheme.Color.neon)
            Text("MK TERMINAL")
                .font(MKFont.caption())
                .tracking(1.5)
                .foregroundStyle(MKTheme.Color.neon)
            Spacer()
            Text("\(events.count) linhas")
                .font(MKFont.caption())
                .foregroundStyle(MKTheme.Color.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}

#Preview {
    ZStack {
        MKBackground()
        TerminalPanel(events: [
            .init(source: "SYSTEM", message: "MK FLIP inicializado", severity: .success),
            .init(source: "SYSTEM", message: "0/13 módulos online · IA offline")
        ])
        .padding()
    }
}
