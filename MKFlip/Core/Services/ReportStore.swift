import Foundation
import Observation

/// Armazena relatórios gerados na sessão e os persiste em disco (JSON no
/// diretório de documentos). Interface estável para a Fase 5 trocar por SwiftData.
@MainActor
@Observable
final class ReportStore {
    private(set) var reports: [Report] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("mkflip_reports.json")
    }()

    init() { load() }

    func add(_ report: Report) {
        reports.insert(report, at: 0)   // mais recente primeiro
        save()
    }

    func delete(_ report: Report) {
        reports.removeAll { $0.id == report.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder.mk.decode([Report].self, from: data) else { return }
        reports = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder.mk.encode(reports) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

extension JSONEncoder {
    static let mk: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted]
        return e
    }()
}

extension JSONDecoder {
    static let mk: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
