import Foundation

/// Estado da camada de IA. Sem conexão configurada, o app **declara** offline —
/// nunca simula uma IA conectada (requisito do projeto).
enum AIStatus: String, Sendable {
    case offline        // nenhuma API configurada
    case localOnly      // apenas heurísticas locais disponíveis
    case connected      // API remota configurada e acessível

    var label: String {
        switch self {
        case .offline: "IA OFFLINE"
        case .localOnly: "IA LOCAL"
        case .connected: "IA CONECTADA"
        }
    }
}

/// Snapshot do estado geral do sistema, exibido no topo do dashboard.
struct SystemStatus: Sendable {
    var aiStatus: AIStatus
    var onlineModules: Int
    var totalModules: Int
    var uptime: TimeInterval

    static let placeholder = SystemStatus(
        aiStatus: .offline,
        onlineModules: 0,
        totalModules: ModuleID.allCases.count,
        uptime: 0
    )
}
