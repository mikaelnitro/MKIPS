import Foundation

/// Resultado da auditoria de uma senha.
struct PasswordAudit: Sendable {
    let length: Int
    let poolSize: Int           // tamanho do alfabeto estimado
    let entropyBits: Double     // log2(pool) * length
    let strength: Strength
    let patterns: [String]      // fraquezas detectadas
    let recommendations: [String]

    enum Strength: String, Sendable {
        case veryWeak = "Muito fraca"
        case weak = "Fraca"
        case moderate = "Moderada"
        case strong = "Forte"
        case veryStrong = "Muito forte"
    }
}

/// Auditor de senhas puramente local — nenhuma senha sai do dispositivo.
///
/// A entropia é uma *estimativa* baseada no tamanho do alfabeto e no
/// comprimento, com penalizações por padrões comuns. Não é uma medida exata
/// de resistência a ataques de dicionário.
enum PasswordAnalyzer {

    private static let common: Set<String> = [
        "123456", "123456789", "password", "senha", "qwerty", "111111",
        "abc123", "12345678", "iloveyou", "admin", "000000", "qwerty123",
        "1q2w3e", "senha123", "brasil", "flamengo"
    ]

    static func audit(_ password: String) -> PasswordAudit {
        let length = password.count
        guard length > 0 else {
            return PasswordAudit(length: 0, poolSize: 0, entropyBits: 0,
                                 strength: .veryWeak, patterns: ["Senha vazia"],
                                 recommendations: ["Defina uma senha."])
        }

        var pool = 0
        if password.contains(where: { $0.isLowercase }) { pool += 26 }
        if password.contains(where: { $0.isUppercase }) { pool += 26 }
        if password.contains(where: { $0.isNumber }) { pool += 10 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { pool += 32 }
        pool = max(pool, 1)

        var entropy = Double(length) * log2(Double(pool))

        var patterns: [String] = []
        let lower = password.lowercased()

        if common.contains(lower) {
            patterns.append("Senha presente em listas comuns de vazamentos")
            entropy = min(entropy, 10)
        }
        if isSequential(lower) { patterns.append("Contém sequência (ex.: abc, 123, qwerty)") ; entropy -= 10 }
        if hasRepeats(password) { patterns.append("Caracteres repetidos em excesso"); entropy -= 8 }
        if password.allSatisfy({ $0.isNumber }) { patterns.append("Somente dígitos"); entropy -= 5 }
        if length < 8 { patterns.append("Comprimento abaixo de 8 caracteres") }

        entropy = max(entropy, 0)

        let strength: PasswordAudit.Strength = switch entropy {
        case ..<28: .veryWeak
        case ..<36: .weak
        case ..<60: .moderate
        case ..<128: .strong
        default: .veryStrong
        }

        var recs: [String] = []
        if length < 12 { recs.append("Use pelo menos 12–16 caracteres.") }
        if pool < 62 { recs.append("Misture maiúsculas, minúsculas, números e símbolos.") }
        if !patterns.isEmpty { recs.append("Evite palavras comuns e sequências previsíveis.") }
        recs.append("Prefira um gerenciador de senhas e frases longas aleatórias.")

        return PasswordAudit(length: length, poolSize: pool, entropyBits: entropy,
                             strength: strength, patterns: patterns, recommendations: recs)
    }

    private static func isSequential(_ s: String) -> Bool {
        let seqs = ["abcdefghijklmnopqrstuvwxyz", "0123456789", "qwertyuiop", "asdfghjkl"]
        let chars = Array(s)
        guard chars.count >= 3 else { return false }
        for seq in seqs {
            let seqChars = Array(seq)
            for i in 0...(seqChars.count - 3) {
                let window = String(seqChars[i..<i+3])
                if s.contains(window) { return true }
            }
        }
        return false
    }

    private static func hasRepeats(_ s: String) -> Bool {
        let chars = Array(s)
        guard chars.count >= 3 else { return false }
        for i in 0...(chars.count - 3) where chars[i] == chars[i+1] && chars[i+1] == chars[i+2] {
            return true
        }
        return false
    }
}
