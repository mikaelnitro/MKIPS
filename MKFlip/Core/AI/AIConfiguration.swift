import Foundation

/// Configuração da camada de IA remota — **compatível com a API OpenAI**
/// (`/chat/completions`), que a maioria dos provedores gratuitos implementa
/// (Groq, OpenRouter, Together, modelos locais etc.).
///
/// A **chave** fica apenas no Keychain (nunca em UserDefaults nem no código) e é
/// inserida manualmente pelo usuário nos Ajustes. Base URL e modelo ficam em
/// UserDefaults (não são segredos). Tudo via funções estáticas — sem estado
/// mutável compartilhado, seguro para concorrência.
enum AIConfiguration {

    private static let keyName = "ai_api_key"
    private static let baseURLKey = "ai_base_url"
    private static let modelKey = "ai_model"

    static let apiVersionNote = "OpenAI-compatible /chat/completions"

    /// Provedores gratuitos pré-configurados. O usuário escolhe um e cola a chave.
    struct Provider: Identifiable, Sendable {
        let id: String
        let name: String
        let baseURL: String
        let model: String
        let signupURL: String
    }

    static let providers: [Provider] = [
        Provider(id: "groq", name: "Groq (grátis)",
                 baseURL: "https://api.groq.com/openai/v1",
                 model: "llama-3.3-70b-versatile",
                 signupURL: "https://console.groq.com/keys"),
        Provider(id: "openrouter", name: "OpenRouter (modelos :free)",
                 baseURL: "https://openrouter.ai/api/v1",
                 model: "meta-llama/llama-3.3-70b-instruct:free",
                 signupURL: "https://openrouter.ai/keys"),
        Provider(id: "custom", name: "Personalizado",
                 baseURL: "", model: "", signupURL: "")
    ]

    static let defaultBaseURL = "https://api.groq.com/openai/v1"
    static let defaultModel = "llama-3.3-70b-versatile"

    // MARK: Chave (Keychain) — inserida manualmente pelo usuário

    static var apiKey: String? { KeychainStore.get(keyName) }

    static var isConfigured: Bool { (apiKey?.isEmpty == false) }

    @discardableResult
    static func setAPIKey(_ key: String?) -> Bool {
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return KeychainStore.set(trimmed, for: keyName)
        } else {
            return KeychainStore.delete(keyName)
        }
    }

    // MARK: Base URL / modelo (UserDefaults)

    static var baseURL: String {
        get { UserDefaults.standard.string(forKey: baseURLKey) ?? defaultBaseURL }
        set { UserDefaults.standard.set(newValue, forKey: baseURLKey) }
    }

    static var model: String {
        get { UserDefaults.standard.string(forKey: modelKey) ?? defaultModel }
        set { UserDefaults.standard.set(newValue, forKey: modelKey) }
    }

    /// URL final de chat completions, normalizando a barra ao fim da base.
    static var chatCompletionsURL: URL? {
        var base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while base.hasSuffix("/") { base.removeLast() }
        guard !base.isEmpty else { return nil }
        // Permite que o usuário já informe o caminho completo, se quiser.
        if base.hasSuffix("/chat/completions") { return URL(string: base) }
        return URL(string: base + "/chat/completions")
    }
}
