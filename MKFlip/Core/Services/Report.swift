import Foundation

/// Relatório gerado por qualquer ferramenta. Estrutura comum para exportação.
struct Report: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let tool: String
    let title: String
    let createdAt: Date
    let subject: String          // o que foi analisado
    let sections: [Section]

    struct Section: Codable, Sendable, Hashable {
        let heading: String
        let lines: [String]
    }

    init(id: UUID = UUID(), tool: String, title: String, createdAt: Date = Date(),
         subject: String, sections: [Section]) {
        self.id = id
        self.tool = tool
        self.title = title
        self.createdAt = createdAt
        self.subject = subject
        self.sections = sections
    }

    /// Renderização em texto puro — base para o .txt e para a prévia na UI.
    var plainText: String {
        var out = "MK FLIP — RELATÓRIO\n"
        out += String(repeating: "=", count: 40) + "\n"
        out += "Ferramenta : \(tool)\n"
        out += "Título     : \(title)\n"
        out += "Assunto    : \(subject)\n"
        out += "Data/Hora  : \(Report.stamp.string(from: createdAt))\n"
        out += String(repeating: "=", count: 40) + "\n\n"
        for section in sections {
            out += section.heading.uppercased() + "\n"
            out += String(repeating: "-", count: section.heading.count) + "\n"
            for line in section.lines { out += line + "\n" }
            out += "\n"
        }
        out += "Gerado por MK FLIP — AI Cyber Intelligence\n"
        return out
    }

    static let stamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy HH:mm:ss"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()
}
