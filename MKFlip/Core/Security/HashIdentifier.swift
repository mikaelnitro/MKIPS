import Foundation

/// Palpite sobre o tipo de um hash a partir de comprimento e alfabeto.
/// Heurístico e honesto: retorna *candidatos*, não certezas.
struct HashGuess: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let confidence: String   // "provável" | "possível"
}

enum HashIdentifier {

    static func identify(_ raw: String) -> [HashGuess] {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return [] }

        let isHex = s.allSatisfy { $0.isHexDigit }
        let isBase64Like = s.allSatisfy {
            $0.isLetter || $0.isNumber || $0 == "+" || $0 == "/" || $0 == "="
        }

        var guesses: [HashGuess] = []

        if isHex {
            switch s.count {
            case 32: guesses.append(.init(name: "MD5", confidence: "provável"))
                     guesses.append(.init(name: "NTLM / MD4", confidence: "possível"))
            case 40: guesses.append(.init(name: "SHA-1", confidence: "provável"))
                     guesses.append(.init(name: "RIPEMD-160", confidence: "possível"))
            case 56: guesses.append(.init(name: "SHA-224", confidence: "provável"))
            case 64: guesses.append(.init(name: "SHA-256", confidence: "provável"))
                     guesses.append(.init(name: "SHA3-256 / BLAKE2s", confidence: "possível"))
            case 96: guesses.append(.init(name: "SHA-384", confidence: "provável"))
            case 128: guesses.append(.init(name: "SHA-512", confidence: "provável"))
                      guesses.append(.init(name: "SHA3-512 / BLAKE2b", confidence: "possível"))
            default: break
            }
        }

        if s.hasPrefix("$2a$") || s.hasPrefix("$2b$") || s.hasPrefix("$2y$") {
            guesses.append(.init(name: "bcrypt", confidence: "provável"))
        }
        if s.hasPrefix("$argon2") {
            guesses.append(.init(name: "Argon2", confidence: "provável"))
        }
        if s.hasPrefix("$6$") { guesses.append(.init(name: "sha512crypt", confidence: "provável")) }
        if s.hasPrefix("$5$") { guesses.append(.init(name: "sha256crypt", confidence: "provável")) }

        if guesses.isEmpty && isBase64Like && s.count % 4 == 0 {
            guesses.append(.init(name: "Base64 (não é hash)", confidence: "possível"))
        }
        if guesses.isEmpty {
            guesses.append(.init(name: "Formato não reconhecido", confidence: "possível"))
        }
        return guesses
    }
}
