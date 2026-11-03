import Foundation

/// Severidade de um evento no histórico de atividades / terminal.
enum ActivitySeverity: String, Codable, Sendable {
    case info
    case success
    case warning
    case error

    var glyph: String {
        switch self {
        case .info: "›"
        case .success: "✓"
        case .warning: "!"
        case .error: "✕"
        }
    }
}

/// Um evento registrado — alimenta tanto o histórico quanto o terminal.
///
/// É `Identifiable`/`Hashable` para uso direto em `List`/`ForEach`, e
/// `Codable` para persistência futura (SwiftData/arquivo) sem reescrita.
struct ActivityEvent: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let source: String        // ex.: "CRYPTO", "NFC", "SYSTEM"
    let message: String
    let severity: ActivitySeverity

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: String,
        message: String,
        severity: ActivitySeverity = .info
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.message = message
        self.severity = severity
    }

    /// Carimbo de hora curto `HH:mm:ss` para a linha do terminal.
    var clock: String {
        ActivityEvent.clockFormatter.string(from: timestamp)
    }

    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()
}
