import Foundation

/// Inteligência local (offline) do MK FLIP. Interpreta comandos em linguagem
/// natural, executa operações reais quando possível e, caso contrário, roteia
/// para o módulo certo ou explica a limitação — sem jamais inventar resultados.
struct LocalIntelligence: AIProvider {
    var displayStatus: AIStatus { .localOnly }

    private let doh = DoHClient()

    func respond(to prompt: String) async -> AIResponse {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()
        guard !lower.isEmpty else {
            return .init(text: "Diga o que precisa analisar. Ex.: \"gere o hash de senha123\" ou \"analise https://exemplo.com\".",
                         suggestedModule: nil, isGrounded: false)
        }

        // 1) Operações reais executáveis localmente -----------------------------

        if lower.contains("hash"), let subject = afterKeyword(text, ["de ", "para ", "do "]) ?? lastToken(text) {
            let sha = HashEngine.hash(subject, with: .sha256)
            return .init(text: "SHA-256 de \"\(subject)\":\n\(sha)\n\n(Hash é via de mão única, não é reversível.)",
                         suggestedModule: .cryptography, isGrounded: true)
        }

        if (lower.contains("senha") || lower.contains("password") || lower.contains("força")),
           let token = extractToken(text) {
            let a = PasswordAnalyzer.audit(token)
            let weak = a.patterns.isEmpty ? "sem padrões fracos óbvios" : a.patterns.joined(separator: "; ")
            return .init(text: "Força: \(a.strength.rawValue) · ~\(Int(a.entropyBits)) bits.\nObservações: \(weak).",
                         suggestedModule: .passwordLab, isGrounded: true)
        }

        if let url = extractURL(text), lower.contains("url") || lower.contains("link") || lower.contains("analis") {
            let r = URLAnalyzer.analyze(url)
            let signals = r.riskSignals.isEmpty ? "sem sinais óbvios de risco" : r.riskSignals.joined(separator: "; ")
            return .init(text: "URL (\(r.kind.rawValue)) · risco \(r.riskLevel.rawValue).\n\(signals).\nNão abri o link.",
                         suggestedModule: .qrIntelligence, isGrounded: true)
        }

        if lower.contains("base64") {
            if lower.contains("decod"), let t = extractToken(text), let dec = EncodingTools.base64Decode(t) {
                return .init(text: "Base64 decodificado:\n\(dec)", suggestedModule: .cryptography, isGrounded: true)
            }
            if let t = extractToken(text) {
                return .init(text: "Base64:\n\(EncodingTools.base64Encode(t))",
                             suggestedModule: .cryptography, isGrounded: true)
            }
        }

        if (lower.contains("dns") || lower.contains("domínio") || lower.contains("dominio")),
           let host = extractDomain(text) {
            let records = await doh.query(host, types: [.A, .AAAA, .MX, .NS])
            if records.isEmpty {
                return .init(text: "Não obtive registros DNS públicos para \(host) agora.",
                             suggestedModule: .osint, isGrounded: true)
            }
            let lines = records.prefix(8).map { "\($0.type): \($0.value)" }.joined(separator: "\n")
            return .init(text: "Registros DNS de \(host):\n\(lines)", suggestedModule: .osint, isGrounded: true)
        }

        // 2) Explicação de termos técnicos --------------------------------------

        if lower.contains("explique") || lower.contains("o que é") || lower.contains("o que e") {
            if let (term, def) = glossaryMatch(lower) {
                return .init(text: "\(term): \(def)", suggestedModule: nil, isGrounded: false)
            }
        }

        // 3) Roteamento por intenção --------------------------------------------

        if let routed = routeByKeyword(lower) {
            let m = ModuleCatalog.module(routed)
            return .init(text: "Isso é trabalho do módulo \(m.name). Abra-o para executar: \(m.subtitle).",
                         suggestedModule: routed, isGrounded: false)
        }

        // 4) Limitação honesta --------------------------------------------------

        return .init(
            text: "Não identifiquei uma operação que eu consiga executar localmente para isso. "
                + "Posso: gerar hashes, analisar URLs, auditar senhas, consultar DNS e explicar termos. "
                + "Integração com IA remota requer configurar uma API (atualmente offline).",
            suggestedModule: nil, isGrounded: false)
    }

    // MARK: Roteamento / glossário

    private func routeByKeyword(_ lower: String) -> ModuleID? {
        if lower.contains("nfc") { return .nfcLab }
        if lower.contains("bluetooth") || lower.contains("ble") { return .bluetooth }
        if lower.contains("qr") { return .qrIntelligence }
        if lower.contains("arquivo") || lower.contains("forense") { return .forensics }
        if lower.contains("rede") || lower.contains("porta") { return .network }
        if lower.contains("web") || lower.contains("https") || lower.contains("certificado") { return .webSecurity }
        if lower.contains("osint") || lower.contains("investig") { return .osint }
        if lower.contains("revers") || lower.contains("binário") || lower.contains("binario") { return .aiReverse }
        if lower.contains("relatório") || lower.contains("relatorio") { return .reports }
        if lower.contains("terminal") || lower.contains("comando") { return .terminal }
        return nil
    }

    private static let glossary: [(String, String)] = [
        ("hash", "resumo de tamanho fixo de uma entrada; mudar 1 bit muda todo o resultado. Não é reversível."),
        ("entropia", "medida de imprevisibilidade. Em senhas, mais bits = mais difícil de adivinhar."),
        ("tls", "protocolo que cifra a conexão (o 'S' do HTTPS) e autentica o servidor por certificado."),
        ("ndef", "formato padrão de dados de tags NFC (registros de URI, texto, MIME)."),
        ("rssi", "intensidade do sinal recebido em dBm; mais próximo de 0 = sinal mais forte."),
        ("osint", "coleta de informações a partir de fontes públicas e abertas."),
        ("base64", "codificação reversível de binário em texto ASCII. Não é criptografia."),
        ("mac address", "identificador de hardware de uma interface de rede."),
        ("sha-256", "função de hash da família SHA-2 com saída de 256 bits (64 hex).")
    ]

    private func glossaryMatch(_ lower: String) -> (String, String)? {
        Self.glossary.first { lower.contains($0.0) }
    }

    // MARK: Extração

    private func afterKeyword(_ text: String, _ keywords: [String]) -> String? {
        let lower = text.lowercased()
        for kw in keywords {
            if let range = lower.range(of: kw) {
                let rest = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !rest.isEmpty { return rest.components(separatedBy: " ").first }
            }
        }
        return nil
    }

    private func lastToken(_ text: String) -> String? {
        text.components(separatedBy: .whitespaces).last(where: { !$0.isEmpty })
    }

    private func extractToken(_ text: String) -> String? {
        text.components(separatedBy: .whitespaces)
            .first { $0.count >= 4 && !$0.lowercased().contains("senha") && !$0.lowercased().contains("hash")
                     && !$0.lowercased().contains("base64") && !$0.lowercased().contains("força") }
    }

    private func extractURL(_ text: String) -> String? {
        text.components(separatedBy: .whitespaces).first { $0.lowercased().hasPrefix("http") }
    }

    private func extractDomain(_ text: String) -> String? {
        text.components(separatedBy: .whitespaces)
            .first { $0.contains(".") && !$0.contains(" ") && !$0.hasPrefix("http") }
            .map { $0.replacingOccurrences(of: ",", with: "") }
    }
}
