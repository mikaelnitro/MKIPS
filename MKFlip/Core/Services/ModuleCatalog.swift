import Foundation

/// Catálogo estático dos módulos do MK FLIP.
///
/// O `state` de cada módulo reflete honestamente o build atual: `online` só
/// para o que já funciona, `comingSoon` para o que ainda não foi implementado.
/// Nenhum cartão promete um resultado que o app não entrega.
enum ModuleCatalog {

    static let all: [ToolModule] = [
        ToolModule(id: .mkAI, name: "MK AI",
                   subtitle: "Inteligência central · linguagem natural",
                   systemImage: "brain.head.profile", state: .online, phase: 5),

        ToolModule(id: .terminal, name: "Cyber Terminal",
                   subtitle: "Console de comandos reais",
                   systemImage: "terminal", state: .online, phase: 2),

        ToolModule(id: .cryptography, name: "Cryptography Lab",
                   subtitle: "Hash · Base64 · hex · chaves",
                   systemImage: "lock.shield", state: .online, phase: 2),

        ToolModule(id: .qrIntelligence, name: "QR Intelligence",
                   subtitle: "Leitura e análise de QR Codes",
                   systemImage: "qrcode.viewfinder", state: .online, phase: 2),

        ToolModule(id: .forensics, name: "Digital Forensics",
                   subtitle: "Arquivos · metadados · hashes",
                   systemImage: "doc.text.magnifyingglass", state: .online, phase: 2),

        ToolModule(id: .nfcLab, name: "NFC Lab",
                   subtitle: "Leitura de tags NFC compatíveis",
                   systemImage: "wave.3.right.circle", state: .conditional, phase: 3),

        ToolModule(id: .bluetooth, name: "Bluetooth Intelligence",
                   subtitle: "Dispositivos BLE próximos",
                   systemImage: "dot.radiowaves.left.and.right", state: .conditional, phase: 3),

        ToolModule(id: .network, name: "Network Intelligence",
                   subtitle: "Diagnóstico de redes autorizadas",
                   systemImage: "network", state: .online, phase: 3),

        ToolModule(id: .webSecurity, name: "Web Security",
                   subtitle: "DNS · TLS · cabeçalhos HTTP",
                   systemImage: "globe.badge.chevron.backward", state: .online, phase: 4),

        ToolModule(id: .osint, name: "OSINT Intelligence",
                   subtitle: "Investigação de dados públicos",
                   systemImage: "person.crop.circle.badge.questionmark", state: .online, phase: 4),

        ToolModule(id: .passwordLab, name: "Password Lab",
                   subtitle: "Força e entropia de senhas",
                   systemImage: "key.horizontal", state: .online, phase: 4),

        ToolModule(id: .aiReverse, name: "AI Reverse",
                   subtitle: "Laboratório de engenharia reversa",
                   systemImage: "cpu", state: .online, phase: 4),

        ToolModule(id: .reports, name: "Relatórios",
                   subtitle: "Central de relatórios · PDF/TXT",
                   systemImage: "doc.richtext", state: .online, phase: 5)
    ]

    static func module(_ id: ModuleID) -> ToolModule {
        all.first { $0.id == id } ?? all[0]
    }

    static var onlineCount: Int {
        all.filter { $0.state == .online }.count
    }
}
