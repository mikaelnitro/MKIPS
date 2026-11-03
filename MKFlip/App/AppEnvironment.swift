import SwiftUI
import Observation

/// Contêiner de dependências compartilhadas do app.
///
/// Mantém os serviços de tempo de vida da aplicação num só lugar e os injeta
/// no ambiente SwiftUI. Novos serviços (IA, persistência) entram aqui nas
/// próximas fases sem tocar nas views existentes.
@MainActor
@Observable
final class AppEnvironment {
    let activityLog: ActivityLog
    let router: AppRouter
    let reportStore: ReportStore

    private let startDate = Date()

    init(activityLog: ActivityLog = ActivityLog(),
         router: AppRouter = AppRouter(),
         reportStore: ReportStore = ReportStore()) {
        self.activityLog = activityLog
        self.router = router
        self.reportStore = reportStore
    }

    /// Snapshot de status para o cabeçalho do dashboard.
    var status: SystemStatus {
        SystemStatus(
            // Sem API remota configurada, mas a inteligência LOCAL opera — declarado honestamente.
            aiStatus: .localOnly,
            onlineModules: ModuleCatalog.onlineCount,
            totalModules: ModuleCatalog.all.count,
            uptime: Date().timeIntervalSince(startDate)
        )
    }

    /// Evento de inicialização para o terminal/histórico.
    func bootstrap() {
        activityLog.log("SYSTEM", "MK FLIP inicializado · build 0.1.0", severity: .success)
        activityLog.log("SYSTEM",
                        "\(ModuleCatalog.onlineCount)/\(ModuleCatalog.all.count) módulos online · IA local ativa",
                        severity: .info)
    }
}
