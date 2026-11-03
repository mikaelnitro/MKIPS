import Foundation

/// Cliente DNS-over-HTTPS (resolvedor público Cloudflare) para consultar
/// registros que o `getaddrinfo` não expõe (MX, TXT, NS, CNAME).
///
/// Só envia o domínio informado pelo usuário ao resolvedor público — nenhum
/// dado da conta. Sem chave de API.
struct DoHClient {

    struct Record: Identifiable, Sendable {
        let id = UUID()
        let type: String
        let value: String
    }

    enum RecordType: String, CaseIterable, Sendable {
        case A, AAAA, MX, TXT, NS, CNAME
    }

    func query(_ domain: String, types: [RecordType] = RecordType.allCases) async -> [Record] {
        let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        guard !clean.isEmpty else { return [] }

        var records: [Record] = []
        await withTaskGroup(of: [Record].self) { group in
            for type in types {
                group.addTask { await self.queryOne(clean, type: type) }
            }
            for await batch in group { records.append(contentsOf: batch) }
        }
        // Ordena por tipo para apresentação estável.
        let order = RecordType.allCases.map(\.rawValue)
        return records.sorted {
            (order.firstIndex(of: $0.type) ?? 99, $0.value) < (order.firstIndex(of: $1.type) ?? 99, $1.value)
        }
    }

    private func queryOne(_ domain: String, type: RecordType) async -> [Record] {
        guard var comps = URLComponents(string: "https://cloudflare-dns.com/dns-query") else { return [] }
        comps.queryItems = [.init(name: "name", value: domain), .init(name: "type", value: type.rawValue)]
        guard let url = comps.url else { return [] }

        var request = URLRequest(url: url)
        request.setValue("application/dns-json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 8

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let answers = json["Answer"] as? [[String: Any]] else { return [] }
            return answers.compactMap { ans in
                guard let value = ans["data"] as? String else { return nil }
                return Record(type: type.rawValue, value: value)
            }
        } catch {
            return []
        }
    }
}
