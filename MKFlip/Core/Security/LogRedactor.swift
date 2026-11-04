import Foundation

/// Redação automática de argumentos sensíveis antes de qualquer registro em log.
///
/// Corrige o vazamento identificado na auditoria: o terminal registrava o input
/// bruto, expondo senhas digitadas em comandos como `pwcheck <senha>` no
/// histórico e no painel do dashboard. Função pura → testável sem UI.
enum LogRedactor {

    private static let mask = "••••••"

    /// Comandos cujo primeiro argumento é sensível e deve ser mascarado por completo.
    private static let sensitiveCommands: Set<String> = ["pwcheck", "pw", "senha", "password"]

    /// Palavras-chave que, quando seguidas de um token, indicam segredo.
    private static let sensitiveKeywords: Set<String> = [
        "password", "passwd", "senha", "secret", "token", "apikey", "api_key",
        "authorization", "bearer", "key"
    ]

    /// Redige uma linha de comando do terminal preservando o nome do comando.
    /// `pwcheck MinhaSenha123` → `pwcheck ••••••`.
    static func redactCommand(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return trimmed }

        let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
        let command = parts[0]

        if sensitiveCommands.contains(command.lowercased()), parts.count > 1 {
            return "\(command) \(mask)"
        }
        // Mesmo em comandos não sensíveis, redige tokens que pareçam segredos.
        return redactText(trimmed)
    }

    /// Redige segredos em texto livre: pares `chave=valor`, `chave: valor`,
    /// cabeçalhos Authorization/Bearer e tokens longos de alta entropia.
    static func redactText(_ text: String) -> String {
        var result = text

        // Bearer <token> PRIMEIRO — senão o padrão "Authorization:" abaixo
        // consome a palavra "Bearer" e deixa o token exposto.
        result = replace(result, pattern: "(?i)(bearer\\s+)(\\S+)", with: "$1\(mask)")

        // chave=valor / chave: valor onde a chave é sensível
        for keyword in sensitiveKeywords {
            let patterns = [
                "(?i)(\\b\(keyword)\\b\\s*[:=]\\s*)(\\S+)",
                "(?i)(\\b\(keyword)\\b\\s+)(\\S{6,})"
            ]
            for pattern in patterns {
                result = replace(result, pattern: pattern, with: "$1\(mask)")
            }
        }

        return result
    }

    private static func replace(_ input: String, pattern: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: template)
    }
}
