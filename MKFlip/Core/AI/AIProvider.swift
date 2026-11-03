import Foundation

/// Resposta da camada de IA, com possível ação de roteamento para um módulo.
struct AIResponse: Sendable {
    let text: String
    let suggestedModule: ModuleID?
    let isGrounded: Bool   // true = resultado real local; false = explicação/roteamento
}

/// Contrato de qualquer provedor de IA. Permite trocar a inteligência local
/// por uma API remota na Fase 5 sem tocar na UI.
protocol AIProvider: Sendable {
    var displayStatus: AIStatus { get }
    func respond(to prompt: String) async -> AIResponse
}

/// Provedor remoto — **arquitetura pronta, não ativa**. Lê a chave do Keychain
/// (nunca do código). Enquanto não houver chave configurada e implementação de
/// rede, declara-se offline e não simula conexão.
struct RemoteAIProvider: AIProvider {
    static let keyName = "ai_api_key"

    var displayStatus: AIStatus {
        KeychainStore.get(Self.keyName) == nil ? .offline : .connected
    }

    func respond(to prompt: String) async -> AIResponse {
        // Sem chave → não simula uma IA conectada (requisito do projeto).
        guard KeychainStore.get(Self.keyName) != nil else {
            return AIResponse(
                text: "Nenhuma API de IA configurada. Operando apenas com inteligência local. "
                    + "Configure uma chave no Keychain para habilitar respostas remotas.",
                suggestedModule: nil, isGrounded: false)
        }
        // Ponto de integração futuro (ex.: Claude API). Enquanto a implementação
        // de rede não existe, informamos a limitação em vez de inventar.
        return AIResponse(
            text: "Integração remota ainda não implementada neste build. "
                + "A arquitetura está pronta para receber o cliente HTTP da API.",
            suggestedModule: nil, isGrounded: false)
    }
}
