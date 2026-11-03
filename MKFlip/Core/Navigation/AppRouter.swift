import SwiftUI
import Observation

/// Rota de navegação tipada. Cada módulo é um destino; empurrado numa
/// `NavigationStack` a partir do dashboard ou do terminal.
enum AppRoute: Hashable {
    case module(ModuleID)
    case settings
}

/// Roteador observável que detém o caminho da `NavigationStack`.
///
/// Centralizar o `path` permite que terminal e IA (fases futuras) naveguem
/// programaticamente — ex.: a MK AI abrir o módulo que decidiu usar.
@MainActor
@Observable
final class AppRouter {
    var path = NavigationPath()

    func open(_ module: ModuleID) {
        path.append(AppRoute.module(module))
    }

    func openSettings() {
        path.append(AppRoute.settings)
    }

    func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
