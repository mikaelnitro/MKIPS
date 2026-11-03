import Foundation

/// Conversões reversíveis de codificação: Base64 e hexadecimal.
/// Diferente de hash — explicitamente reversível (a UI deixa isso claro).
enum EncodingTools {

    // MARK: Base64

    static func base64Encode(_ text: String) -> String {
        Data(text.utf8).base64EncodedString()
    }

    /// Decodifica Base64 → texto UTF-8, ou `nil` se inválido/não-texto.
    static func base64Decode(_ b64: String) -> String? {
        let cleaned = b64.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: cleaned, options: [.ignoreUnknownCharacters]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    // MARK: Hex

    static func hexEncode(_ text: String) -> String {
        Data(text.utf8).map { String(format: "%02x", $0) }.joined()
    }

    /// Decodifica string hex (com ou sem espaços) → texto UTF-8.
    static func hexDecode(_ hex: String) -> String? {
        let cleaned = hex.filter { $0.isHexDigit }
        guard cleaned.count % 2 == 0 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(cleaned.count / 2)
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let next = cleaned.index(index, offsetBy: 2)
            guard let byte = UInt8(cleaned[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        return String(data: Data(bytes), encoding: .utf8)
    }
}
