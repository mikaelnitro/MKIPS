import Foundation
import Observation

/// Registro central de atividades. Fonte única de verdade para o histórico
/// do dashboard e para as linhas do terminal.
///
/// Mantido em memória nesta fase; a interface `record(_:)` não muda quando a
/// persistência (SwiftData) for adicionada na Fase 5, então nenhum chamador
/// precisará ser reescrito.
@MainActor
@Observable
final class ActivityLog {
    /// Eventos em ordem cronológica (mais antigo → mais recente).
    private(set) var events: [ActivityEvent] = []

    /// Teto de retenção em memória para não crescer indefinidamente numa
    /// sessão longa. ~1k linhas é suficiente para o terminal visível.
    private let maxEvents = 1_000

    init(seed: [ActivityEvent] = []) {
        events = seed
    }

    /// Registra um evento já construído.
    func record(_ event: ActivityEvent) {
        events.append(event)
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
    }

    /// Conveniência: registra a partir dos campos.
    func log(_ source: String, _ message: String, severity: ActivitySeverity = .info) {
        record(ActivityEvent(source: source, message: message, severity: severity))
    }

    /// Eventos mais recentes primeiro, limitados — para o cartão de histórico.
    func recent(_ limit: Int) -> [ActivityEvent] {
        Array(events.suffix(limit).reversed())
    }

    func clear() {
        events.removeAll()
    }
}
