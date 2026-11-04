import SwiftUI

/// Cyber Terminal interativo. Reutiliza o `TerminalPanel` para o histórico e
/// adiciona uma linha de entrada. Cada comando passa pelo `TerminalEngine`,
/// que só executa operações reais.
struct TerminalView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var command = ""
    @State private var history: [String] = []
    @State private var historyIndex = 0
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TerminalPanel(events: env.activityLog.events, maxHeight: .infinity)
                .padding(.horizontal, MKTheme.Metric.spacing)
                .padding(.top, MKTheme.Metric.spacing)

            inputBar
        }
        .background(MKBackground())
        .navigationTitle("Cyber Terminal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            focused = true
            if history.isEmpty {
                env.activityLog.log("TERMINAL", "Sessão iniciada. Digite 'help'.", severity: .info)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            Text("mkflip ›").font(MKFont.mono(13, weight: .bold)).foregroundStyle(MKTheme.Color.neon)
            TextField("comando…", text: $command)
                .font(MKFont.mono(13))
                .foregroundStyle(MKTheme.Color.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .onSubmit(execute)
            Button(action: execute) {
                Image(systemName: "return").foregroundStyle(MKTheme.Color.neon)
            }
            .disabled(command.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(12)
        .background(Color.black)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(MKTheme.Color.neon.opacity(0.2)), alignment: .top)
    }

    private func execute() {
        let input = command.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return }

        // Registra a versão REDIGIDA — senhas em `pwcheck <senha>` e segredos
        // nunca vão para o log/histórico/dashboard. (Correção do vazamento.)
        env.activityLog.log("$", LogRedactor.redactCommand(input), severity: .info)
        history.append(input)
        command = ""

        let result = TerminalEngine.run(input)
        if result.clearScreen {
            env.activityLog.clear()
            env.activityLog.log("TERMINAL", "Tela limpa.", severity: .info)
        }
        for (line, severity) in result.lines {
            env.activityLog.log("OUT", line, severity: severity)
        }
        if let target = result.navigateTo {
            // Pequeno atraso para a linha de saída aparecer antes de navegar.
            // Task @MainActor evita chamar método @MainActor de closure não isolado.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                env.router.open(target)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TerminalView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
