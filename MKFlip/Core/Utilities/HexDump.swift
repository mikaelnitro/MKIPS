import Foundation

/// Gera visualização hexadecimal estilo `hexdump -C`:
/// `offset  2 colunas de 8 bytes  |ascii|`.
enum HexDump {

    /// Produz as linhas do dump. `maxBytes` limita o trabalho em arquivos grandes.
    static func lines(from data: Data, maxBytes: Int = 4096) -> [String] {
        let slice = data.prefix(maxBytes)
        var result: [String] = []
        var offset = 0
        let bytes = [UInt8](slice)

        while offset < bytes.count {
            let end = min(offset + 16, bytes.count)
            let chunk = bytes[offset..<end]

            let hexParts = chunk.map { String(format: "%02x", $0) }
            let left = hexParts.prefix(8).joined(separator: " ")
            let right = hexParts.dropFirst(8).joined(separator: " ")
            let hexColumn = right.isEmpty ? left : "\(left)  \(right)"
            let padded = hexColumn.padding(toLength: 49, withPad: " ", startingAt: 0)

            let ascii = chunk.map { b -> Character in
                (b >= 0x20 && b < 0x7F) ? Character(UnicodeScalar(b)) : "."
            }

            result.append(String(format: "%08x  %@ |%@|", offset, padded, String(ascii)))
            offset = end
        }
        return result
    }

    var truncatedNote: String { "Exibindo os primeiros bytes (visualização limitada)." }
}
