import Foundation

/// Classificação do conteúdo de um QR / texto lido.
enum QRContentKind: String, Sendable {
    case url = "URL"
    case wifi = "Rede Wi-Fi"
    case email = "E-mail"
    case phone = "Telefone"
    case geo = "Localização"
    case vcard = "Contato (vCard)"
    case text = "Texto"
}

/// Resultado da análise de uma URL / conteúdo, com sinais de risco.
struct URLAnalysis: Sendable {
    let kind: QRContentKind
    let normalized: String
    let host: String?
    let scheme: String?
    let isHTTPS: Bool
    let riskSignals: [String]   // vazio = sem sinais óbvios
    var riskLevel: RiskLevel {
        switch riskSignals.count {
        case 0: .low
        case 1...2: .medium
        default: .high
        }
    }
    enum RiskLevel: String, Sendable { case low = "Baixo", medium = "Médio", high = "Alto" }
}

/// Analisador de URL/conteúdo. Heurístico e **offline** — não resolve nem abre
/// nada; apenas inspeciona a string. Os destinos nunca são abertos automaticamente.
enum URLAnalyzer {

    private static let shorteners: Set<String> = [
        "bit.ly", "tinyurl.com", "goo.gl", "t.co", "ow.ly", "is.gd",
        "buff.ly", "cutt.ly", "rebrand.ly", "shorturl.at"
    ]
    private static let suspiciousTLDs: Set<String> = [
        "zip", "mov", "xyz", "top", "tk", "gq", "ml", "cf", "ga", "work", "click"
    ]

    static func classify(_ raw: String) -> QRContentKind {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = s.lowercased()
        if lower.hasPrefix("wifi:") { return .wifi }
        if lower.hasPrefix("mailto:") || (s.contains("@") && !s.contains(" ") && s.contains(".") && !lower.contains("http")) { return .email }
        if lower.hasPrefix("tel:") { return .phone }
        if lower.hasPrefix("geo:") { return .geo }
        if lower.hasPrefix("begin:vcard") { return .vcard }
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") { return .url }
        return .text
    }

    static func analyze(_ raw: String) -> URLAnalysis {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let kind = classify(s)

        guard kind == .url, let comps = URLComponents(string: s) else {
            return URLAnalysis(kind: kind, normalized: s, host: nil, scheme: nil,
                               isHTTPS: false, riskSignals: [])
        }

        let host = comps.host?.lowercased()
        let scheme = comps.scheme?.lowercased()
        let isHTTPS = scheme == "https"
        var signals: [String] = []

        if scheme == "http" { signals.append("Conexão sem criptografia (HTTP)") }
        if let host {
            if let shortener = shorteners.first(where: { host == $0 || host.hasSuffix("." + $0) }) {
                signals.append("Encurtador de URL (\(shortener)) — destino oculto")
            }
            if isIPAddress(host) { signals.append("Host é um endereço IP literal, não um domínio") }
            if host.contains("xn--") { signals.append("Domínio com Punycode — possível homógrafo") }
            if let tld = host.split(separator: ".").last, suspiciousTLDs.contains(String(tld)) {
                signals.append("TLD frequentemente abusado (.\(tld))")
            }
            if host.filter({ $0 == "." }).count >= 4 {
                signals.append("Muitos subdomínios — possível ofuscação")
            }
            if host.contains("@") { signals.append("Caractere '@' no host — possível engano de credencial") }
        }
        if s.contains("@") && (scheme == "http" || scheme == "https") {
            signals.append("Userinfo na URL ('@') — destino real pode diferir do exibido")
        }
        if s.count > 150 { signals.append("URL muito longa — possível ofuscação de parâmetros") }

        return URLAnalysis(kind: .url, normalized: s, host: host, scheme: scheme,
                           isHTTPS: isHTTPS, riskSignals: signals)
    }

    private static func isIPAddress(_ host: String) -> Bool {
        let parts = host.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { Int($0).map { (0...255).contains($0) } ?? false }
    }
}
