import Foundation

/// Resultado da execução de um comando do terminal.
struct CommandResult: Sendable {
    var lines: [(String, ActivitySeverity)]
    var navigateTo: ModuleID? = nil
    var clearScreen: Bool = false
}

/// Motor de comandos do Cyber Terminal.
///
/// Executa **apenas operações reais** já implementadas no app (hash, encode,
/// análise de URL etc.). Não existem comandos decorativos que só animam. Função
/// pura → totalmente testável sem UI.
enum TerminalEngine {

    static let commands: [(name: String, usage: String, desc: String)] = [
        ("help",    "help",                 "Lista os comandos disponíveis"),
        ("clear",   "clear",                "Limpa a tela do terminal"),
        ("status",  "status",               "Mostra o status do sistema"),
        ("modules", "modules",              "Lista os módulos e seus estados"),
        ("hash",    "hash <algo> <texto>",  "Gera hash (md5|sha1|sha256|sha384|sha512)"),
        ("hashid",  "hashid <hash>",        "Identifica o tipo de um hash"),
        ("b64enc",  "b64enc <texto>",       "Codifica em Base64"),
        ("b64dec",  "b64dec <base64>",      "Decodifica Base64"),
        ("hexenc",  "hexenc <texto>",       "Codifica em hexadecimal"),
        ("hexdec",  "hexdec <hex>",         "Decodifica hexadecimal"),
        ("pwcheck", "pwcheck <senha>",      "Audita a força de uma senha (não registra a senha)"),
        ("urlcheck","urlcheck <url>",       "Analisa riscos de uma URL"),
        ("open",    "open <módulo>",        "Abre um módulo (ex.: open crypto)"),
        ("echo",    "echo <texto>",         "Repete o texto"),
        ("version", "version",              "Versão do MK FLIP")
    ]

    static func run(_ rawInput: String) -> CommandResult {
        let input = rawInput.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return CommandResult(lines: []) }

        let parts = input.split(separator: " ", maxSplits: 1).map(String.init)
        let cmd = parts[0].lowercased()
        let arg = parts.count > 1 ? parts[1] : ""

        switch cmd {
        case "help":    return ok(helpLines())
        case "clear":   return CommandResult(lines: [], clearScreen: true)
        case "version": return ok([("MK FLIP v0.1.0 — AI Cyber Intelligence", .info)])
        case "echo":    return ok([(arg, .info)])
        case "status":  return ok(statusLines())
        case "modules": return ok(moduleLines())

        case "hash":
            let sub = arg.split(separator: " ", maxSplits: 1).map(String.init)
            guard sub.count == 2, let algo = parseAlgo(sub[0]) else {
                return err("uso: hash <md5|sha1|sha256|sha384|sha512> <texto>")
            }
            return ok([(HashEngine.hash(sub[1], with: algo), .success)])

        case "hashid":
            guard !arg.isEmpty else { return err("uso: hashid <hash>") }
            let guesses = HashIdentifier.identify(arg)
            return ok(guesses.map { ("\($0.name) — \($0.confidence)", .info) })

        case "b64enc": guard !arg.isEmpty else { return err("uso: b64enc <texto>") }
            return ok([(EncodingTools.base64Encode(arg), .success)])
        case "b64dec": guard !arg.isEmpty else { return err("uso: b64dec <base64>") }
            return EncodingTools.base64Decode(arg).map { ok([($0, .success)]) } ?? err("Base64 inválido")
        case "hexenc": guard !arg.isEmpty else { return err("uso: hexenc <texto>") }
            return ok([(EncodingTools.hexEncode(arg), .success)])
        case "hexdec": guard !arg.isEmpty else { return err("uso: hexdec <hex>") }
            return EncodingTools.hexDecode(arg).map { ok([($0, .success)]) } ?? err("Hex inválido")

        case "pwcheck":
            guard !arg.isEmpty else { return err("uso: pwcheck <senha>") }
            let a = PasswordAnalyzer.audit(arg)
            // Não ecoa a senha — apenas a métrica.
            return ok([("Força: \(a.strength.rawValue) · \(Int(a.entropyBits)) bits · alfabeto \(a.poolSize)", .success)])

        case "urlcheck":
            guard !arg.isEmpty else { return err("uso: urlcheck <url>") }
            let r = URLAnalyzer.analyze(arg)
            var lines: [(String, ActivitySeverity)] = [
                ("Tipo: \(r.kind.rawValue) · Risco: \(r.riskLevel.rawValue)",
                 r.riskLevel == .high ? .error : (r.riskLevel == .medium ? .warning : .success))
            ]
            lines += r.riskSignals.map { ("• \($0)", .warning) }
            if r.riskSignals.isEmpty { lines.append(("Sem sinais óbvios de risco.", .success)) }
            return ok(lines)

        case "open":
            guard let id = parseModule(arg) else {
                return err("módulo desconhecido. Tente: crypto, qr, forensics, network, web, osint, password, nfc, bluetooth, reverse, ai, reports, terminal")
            }
            return CommandResult(lines: [("Abrindo \(ModuleCatalog.module(id).name)…", .info)], navigateTo: id)

        default:
            return err("comando não reconhecido: '\(cmd)'. Digite 'help'.")
        }
    }

    // MARK: Helpers

    private static func ok(_ lines: [(String, ActivitySeverity)]) -> CommandResult { CommandResult(lines: lines) }
    private static func err(_ msg: String) -> CommandResult { CommandResult(lines: [(msg, .error)]) }

    private static func helpLines() -> [(String, ActivitySeverity)] {
        [("Comandos disponíveis:", .info)] +
        commands.map { ("  \($0.usage.padding(toLength: 24, withPad: " ", startingAt: 0)) \($0.desc)", .info) }
    }

    private static func statusLines() -> [(String, ActivitySeverity)] {
        [("Sistema: ONLINE", .success),
         ("IA: LOCAL ativa · remota offline (sem API configurada)", .warning),
         ("Módulos: \(ModuleCatalog.onlineCount)/\(ModuleCatalog.all.count) online", .info)]
    }

    private static func moduleLines() -> [(String, ActivitySeverity)] {
        ModuleCatalog.all.map { m in
            let sev: ActivitySeverity = m.state == .online ? .success : (m.state == .conditional ? .warning : .info)
            return ("\(m.name.padding(toLength: 24, withPad: " ", startingAt: 0)) [\(m.state.label)]", sev)
        }
    }

    private static func parseAlgo(_ s: String) -> HashAlgorithm? {
        switch s.lowercased() {
        case "md5": .md5
        case "sha1", "sha-1": .sha1
        case "sha256", "sha-256": .sha256
        case "sha384", "sha-384": .sha384
        case "sha512", "sha-512": .sha512
        default: nil
        }
    }

    static func parseModule(_ s: String) -> ModuleID? {
        switch s.lowercased() {
        case "crypto", "cryptography": .cryptography
        case "qr": .qrIntelligence
        case "forensics", "forense": .forensics
        case "network", "net", "rede": .network
        case "web", "websecurity": .webSecurity
        case "osint": .osint
        case "password", "pass", "senha": .passwordLab
        case "nfc": .nfcLab
        case "bluetooth", "ble": .bluetooth
        case "reverse", "aireverse": .aiReverse
        case "ai", "mkai": .mkAI
        case "reports", "relatorios", "relatórios": .reports
        case "terminal": .terminal
        default: nil
        }
    }
}
