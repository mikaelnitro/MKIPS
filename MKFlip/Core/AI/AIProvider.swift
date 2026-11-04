import Foundation

/// Resposta da camada de IA, com possível ação de roteamento para um módulo.
struct AIResponse: Sendable {
    let text: String
    let suggestedModule: ModuleID?
    let isGrounded: Bool   // true = resultado real (API ou cálculo local); false = roteamento/limite
}

/// Turno anterior da conversa, enviado para dar contexto à IA.
struct AITurn: Sendable {
    enum Role: String, Sendable { case user, assistant }
    let role: Role
    let text: String
}

/// Contrato de qualquer provedor de IA. A UI depende só disto, então trocar
/// inteligência local por remota (ou de provedor) não exige mudar as views.
protocol AIProvider: Sendable {
    var displayStatus: AIStatus { get }
    func respond(to prompt: String, history: [AITurn], context: String?) async -> AIResponse
}

/// Provedor remoto **real**, compatível com a API OpenAI (`/chat/completions`).
/// Funciona com provedores gratuitos (Groq, OpenRouter, etc.). A chave é lida do
/// Keychain (inserida manualmente pelo usuário). Nunca inventa resultados: sem
/// chave ou em erro, informa a limitação honestamente.
struct RemoteAIProvider: AIProvider {

    var displayStatus: AIStatus { AIConfiguration.isConfigured ? .connected : .offline }

    private let systemPrompt = """
    Você é a MK AI, assistente técnica do app MK FLIP (cibersegurança, análise \
    forense e engenharia reversa para iOS). Responda em português do Brasil, de \
    forma direta e técnica. Explique termos quando útil. Nunca invente resultados \
    de ferramentas: se algo exige executar um módulo do app (NFC, Bluetooth, rede, \
    hash, etc.), diga qual módulo usar. Só oriente uso autorizado e legal.
    """

    func respond(to prompt: String, history: [AITurn], context: String?) async -> AIResponse {
        guard let key = AIConfiguration.apiKey, !key.isEmpty else {
            return AIResponse(
                text: "Nenhuma chave de API configurada. Vá em Configurações → IA, escolha "
                    + "um provedor gratuito (Groq/OpenRouter), gere a chave e cole aqui.",
                suggestedModule: nil, isGrounded: false)
        }
        guard let url = AIConfiguration.chatCompletionsURL else {
            return AIResponse(text: "Endpoint de IA inválido. Verifique a Base URL nos Ajustes.",
                              suggestedModule: nil, isGrounded: false)
        }

        var messages: [[String: Any]] = [["role": "system", "content": fullSystem(context)]]
        messages += history.map { ["role": $0.role.rawValue, "content": $0.text] }
        messages.append(["role": "user", "content": prompt])

        let body: [String: Any] = [
            "model": AIConfiguration.model,
            "messages": messages,
            "max_tokens": 2048,
            "temperature": 0.4
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MK FLIP", forHTTPHeaderField: "X-Title")  // cortesia p/ OpenRouter
        request.timeoutInterval = 60
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return AIResponse(text: "Resposta inválida do servidor.", suggestedModule: nil, isGrounded: false)
            }
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

            guard http.statusCode == 200 else {
                let apiMsg = (json?["error"] as? [String: Any])?["message"] as? String
                    ?? (json?["error"] as? String)
                    ?? "HTTP \(http.statusCode)"
                return AIResponse(text: "Erro da API: \(apiMsg)", suggestedModule: nil, isGrounded: false)
            }
            guard let choices = json?["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return AIResponse(text: "Formato de resposta inesperado do provedor.",
                                  suggestedModule: nil, isGrounded: false)
            }
            let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return AIResponse(text: text.isEmpty ? "(resposta vazia)" : text,
                              suggestedModule: nil, isGrounded: true)
        } catch {
            return AIResponse(text: "Falha de conexão com a IA: \(error.localizedDescription)",
                              suggestedModule: nil, isGrounded: false)
        }
    }

    private func fullSystem(_ context: String?) -> String {
        guard let context, !context.isEmpty else { return systemPrompt }
        return systemPrompt + "\n\nAtividade recente do app (contexto):\n" + context
    }
}
