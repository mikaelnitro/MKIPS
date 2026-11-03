import SwiftUI
import Observation

/// Lógica de apresentação do dashboard. Fina por design — o estado real mora
/// nos serviços (`ActivityLog`, catálogo); o VM apenas deriva o que a view
/// precisa, mantendo a View declarativa e testável.
@MainActor
@Observable
final class DashboardViewModel {
    let modules: [ToolModule] = ModuleCatalog.all

    /// Linhas recentes para o painel de histórico (fora do terminal principal).
    func recentActivity(from log: ActivityLog, limit: Int = 5) -> [ActivityEvent] {
        log.recent(limit)
    }

    func statusTint(_ status: AIStatus) -> Color {
        switch status {
        case .offline: MKTheme.Color.textTertiary
        case .localOnly: MKTheme.Color.warning
        case .connected: MKTheme.Color.neon
        }
    }
}
