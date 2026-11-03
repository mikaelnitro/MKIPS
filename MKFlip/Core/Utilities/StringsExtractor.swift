import Foundation

/// Extrai sequências ASCII imprimíveis de dados binários — como o `strings` do
/// Unix. Útil em forense/reversa para achar URLs, caminhos e mensagens embutidas.
enum StringsExtractor {

    /// Sequências com comprimento mínimo `minLength`, limitadas a `maxResults`.
    static func extract(from data: Data, minLength: Int = 4, maxResults: Int = 500) -> [String] {
        var results: [String] = []
        var current: [UInt8] = []

        for byte in data {
            if byte >= 0x20 && byte < 0x7F {
                current.append(byte)
            } else {
                if current.count >= minLength {
                    results.append(String(decoding: current, as: UTF8.self))
                    if results.count >= maxResults { return results }
                }
                current.removeAll(keepingCapacity: true)
            }
        }
        if current.count >= minLength {
            results.append(String(decoding: current, as: UTF8.self))
        }
        return results
    }

    /// Destaca strings "interessantes" (URLs, caminhos, e-mails, chaves).
    static func interesting(_ strings: [String]) -> [String] {
        strings.filter { s in
            s.contains("http") || s.contains("://") || s.hasPrefix("/") ||
            s.contains("@") || s.lowercased().contains("key") ||
            s.lowercased().contains("token") || s.lowercased().contains("password")
        }
    }
}
