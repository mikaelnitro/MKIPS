import SwiftUI

/// Mensagem no chat da MK AI.
struct AIMessage: Identifiable, Sendable {
    let id = UUID()
    let role: Role
    let text: String
    var suggestedModule: ModuleID? = nil
    var grounded: Bool = false
    enum Role { case user, assistant }
}

/// MK AI — interface de conversa em linguagem natural. Usa o provedor local
/// (offline honesto). Quando a IA roteia para um módulo, oferece um atalho.
struct MKAIView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var messages: [AIMessage] = []
    @State private var input = ""
    @State private var thinking = false

    /// Provedor escolhido em tempo de envio: remoto (IA real) se houver chave
    /// configurada, senão a inteligência local baseada em regras.
    private var currentProvider: AIProvider {
        AIConfiguration.isConfigured ? RemoteAIProvider() : LocalIntelligence()
    }
    private var currentStatus: AIStatus {
        AIConfiguration.isConfigured ? .connected : .localOnly
    }

    private let suggestions = [
        "Gere o hash de senha123",
        "Analise https://bit.ly/abc",
        "Explique o que é entropia",
        "Consulte o DNS de apple.com"
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty { intro }
                        ForEach(messages) { bubble($0) }
                        if thinking {
                            Text("MK AI processando…").font(MKFont.caption())
                                .foregroundStyle(MKTheme.Color.textTertiary)
                        }
                    }
                    .padding(MKTheme.Metric.spacing)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            inputBar
        }
        .background(MKBackground())
        .navigationTitle("MK AI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StatusPill(text: currentStatus.label,
                           tint: currentStatus == .connected ? MKTheme.Color.neon : MKTheme.Color.warning)
            }
        }
    }

    private var intro: some View {
        MKCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("MK AI — Inteligência central")
                    .font(MKFont.title(16)).foregroundStyle(MKTheme.Color.textPrimary)
                Text(AIConfiguration.isConfigured
                     ? "IA **conectada** (\(AIConfiguration.model)). Pergunte à vontade — análise, explicações e relatórios."
                     : "Opero **offline** com inteligência local (hashes, URLs, senhas, DNS, termos). Para IA completa, vá em Configurações → IA, escolha um provedor **gratuito** e cole sua chave.")
                    .font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textSecondary)
                ForEach(suggestions, id: \.self) { s in
                    Button { input = s; send() } label: {
                        HStack {
                            Image(systemName: "sparkles").font(.system(size: 11))
                            Text(s).font(MKFont.body(13))
                            Spacer()
                        }
                        .foregroundStyle(MKTheme.Color.neon)
                    }
                }
            }
        }
    }

    private func bubble(_ m: AIMessage) -> some View {
        HStack {
            if m.role == .user { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 8) {
                Text(m.text)
                    .font(MKFont.body(14))
                    .foregroundStyle(m.role == .user ? MKTheme.Color.background : MKTheme.Color.textPrimary)
                    .textSelection(.enabled)
                if m.grounded {
                    Label("resultado real", systemImage: "checkmark.seal")
                        .font(MKFont.caption()).foregroundStyle(MKTheme.Color.neonDim)
                }
                if let module = m.suggestedModule {
                    Button { env.router.open(module) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: ModuleCatalog.module(module).systemImage)
                            Text("Abrir \(ModuleCatalog.module(module).name)")
                            Image(systemName: "arrow.right")
                        }
                        .font(MKFont.caption())
                        .foregroundStyle(MKTheme.Color.purple)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(m.role == .user ? MKTheme.Color.neon : MKTheme.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(m.role == .user ? Color.clear : MKTheme.Color.hairline, lineWidth: 1)
            )
            .id(m.id)
            if m.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Pergunte à MK AI…", text: $input, axis: .vertical)
                .font(MKFont.body(14)).foregroundStyle(MKTheme.Color.textPrimary)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(MKTheme.Color.background))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MKTheme.Color.hairline, lineWidth: 1))
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(canSend ? MKTheme.Color.neon : MKTheme.Color.textTertiary)
            }
            .disabled(!canSend)
        }
        .padding(12)
        .background(Color.black.opacity(0.4))
    }

    private var canSend: Bool { !input.trimmingCharacters(in: .whitespaces).isEmpty && !thinking }

    private func send() {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        // Histórico anterior (antes de anexar o novo turno) para dar contexto à IA.
        let history: [AITurn] = messages.map {
            AITurn(role: $0.role == .user ? .user : .assistant, text: $0.text)
        }
        // Contexto leve: atividade recente do app.
        let context = env.activityLog.recent(6)
            .map { "\($0.source): \($0.message)" }
            .joined(separator: "\n")

        messages.append(AIMessage(role: .user, text: prompt))
        input = ""
        thinking = true
        env.activityLog.log("MK-AI", "Consulta: \(prompt)", severity: .info)

        let provider = currentProvider
        Task {
            let response = await provider.respond(to: prompt, history: history, context: context)
            await MainActor.run {
                messages.append(AIMessage(role: .assistant, text: response.text,
                                          suggestedModule: response.suggestedModule,
                                          grounded: response.isGrounded))
                thinking = false
                env.activityLog.log("MK-AI",
                                    response.isGrounded ? "Resposta recebida" : "Resposta/roteamento/limite",
                                    severity: .success)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MKAIView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
