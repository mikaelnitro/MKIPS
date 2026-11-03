import SwiftUI

/// Ponto de entrada do MK FLIP.
@main
struct MKFlipApp: App {
    @State private var env: AppEnvironment

    init() {
        let environment = AppEnvironment()
        environment.bootstrap()
        _env = State(initialValue: environment)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(env)
        }
    }
}
