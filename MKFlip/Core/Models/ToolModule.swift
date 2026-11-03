import SwiftUI

/// Estado operacional de um módulo/ferramenta.
enum ModuleState: String, Codable, Sendable {
    /// Implementado e utilizável neste build.
    case online
    /// Depende de hardware/permissão que pode não existir no dispositivo (NFC, BLE...).
    case conditional
    /// Planejado, ainda não implementado nesta fase. Nunca produz resultado falso.
    case comingSoon

    var label: String {
        switch self {
        case .online: "ONLINE"
        case .conditional: "CONDICIONAL"
        case .comingSoon: "EM BREVE"
        }
    }

    var tint: Color {
        switch self {
        case .online: MKTheme.Color.neon
        case .conditional: MKTheme.Color.warning
        case .comingSoon: MKTheme.Color.textTertiary
        }
    }
}

/// Identificador estável de cada módulo. Dirige a navegação tipada.
enum ModuleID: String, CaseIterable, Identifiable, Codable, Sendable {
    case mkAI
    case aiReverse
    case nfcLab
    case bluetooth
    case network
    case webSecurity
    case osint
    case cryptography
    case passwordLab
    case forensics
    case qrIntelligence
    case terminal
    case reports

    var id: String { rawValue }
}

/// Descrição apresentável de um módulo no dashboard.
struct ToolModule: Identifiable, Sendable {
    let id: ModuleID
    let name: String
    let subtitle: String
    let systemImage: String
    let state: ModuleState
    /// Fase do roadmap em que o módulo é entregue (para placeholders honestos).
    let phase: Int

    var isOpenable: Bool { true } // todo cartão navega; destinos não prontos mostram placeholder honesto
}
