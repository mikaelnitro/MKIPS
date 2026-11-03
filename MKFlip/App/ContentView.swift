import SwiftUI

/// Raiz de navegação. Detém a `NavigationStack` e mapeia cada rota tipada para
/// a view real do módulo.
struct ContentView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        @Bindable var router = env.router
        NavigationStack(path: $router.path) {
            DashboardView()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .tint(MKTheme.Color.neon)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .settings:
            SettingsView()
        case .module(let id):
            moduleView(id)
        }
    }

    @ViewBuilder
    private func moduleView(_ id: ModuleID) -> some View {
        switch id {
        case .terminal:       TerminalView()
        case .cryptography:   CryptographyView()
        case .qrIntelligence: QRIntelligenceView()
        case .forensics:      ForensicsView()
        case .passwordLab:    PasswordLabView()
        case .network:        NetworkView()
        case .webSecurity:    WebSecurityView()
        case .osint:          OSINTView()
        case .nfcLab:         NFCLabView()
        case .bluetooth:      BluetoothView()
        case .aiReverse:      AIReverseView()
        case .mkAI:           MKAIView()
        case .reports:        ReportsView()
        }
    }
}

#Preview {
    ContentView()
        .environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
}
