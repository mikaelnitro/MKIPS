import Foundation
import Security

/// Resultado da análise de segurança de uma URL HTTPS.
struct WebScanResult: Sendable {
    let url: String
    let statusCode: Int?
    let server: String?
    let certSubject: String?
    let certIssuer: String?
    let certNotBefore: Date?
    let certNotAfter: Date?
    let presentHeaders: [String: String]
    let findings: [Finding]
    let error: String?

    struct Finding: Sendable, Identifiable {
        let id = UUID()
        let title: String
        let ok: Bool
        let detail: String
    }

    func asReport() -> Report {
        var overview = ["URL: \(url)"]
        if let statusCode { overview.append("HTTP: \(statusCode)") }
        if let server { overview.append("Servidor: \(server)") }
        if let error { overview.append("Erro: \(error)") }

        var certLines: [String] = []
        if let certSubject { certLines.append("Titular: \(certSubject)") }
        if let certIssuer { certLines.append("Emissor: \(certIssuer)") }
        if let nb = certNotBefore { certLines.append("Válido de: \(Report.stamp.string(from: nb))") }
        if let na = certNotAfter { certLines.append("Válido até: \(Report.stamp.string(from: na))") }
        if certLines.isEmpty { certLines = ["(sem dados de certificado)"] }

        return Report(
            tool: "Web Security",
            title: "Análise de \(url)",
            subject: url,
            sections: [
                .init(heading: "Visão geral", lines: overview),
                .init(heading: "Certificado TLS", lines: certLines),
                .init(heading: "Verificações", lines: findings.map { "\($0.ok ? "✓" : "✗") \($0.title) — \($0.detail)" })
            ]
        )
    }
}

/// Faz uma requisição HTTPS e avalia certificado + cabeçalhos de segurança.
/// Pensado para domínios que o usuário possui ou tem autorização para testar.
final class WebSecurityScanner: NSObject, URLSessionDelegate, @unchecked Sendable {

    private var capturedTrust: SecTrust?

    func scan(_ rawURL: String) async -> WebScanResult {
        var urlString = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.lowercased().hasPrefix("http") { urlString = "https://" + urlString }
        guard let url = URL(string: urlString) else {
            return empty(urlString, error: "URL inválida")
        }

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("MKFlip-Scanner/0.1", forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return empty(urlString, error: "Resposta não-HTTP")
            }
            return build(urlString, http: http)
        } catch {
            return empty(urlString, error: error.localizedDescription)
        }
    }

    // MARK: Montagem do resultado

    private func build(_ urlString: String, http: HTTPURLResponse) -> WebScanResult {
        let headers = http.allHeaderFields.reduce(into: [String: String]()) { dict, pair in
            if let k = pair.key as? String { dict[k.lowercased()] = "\(pair.value)" }
        }

        let cert = capturedTrust.flatMap { Self.leafCertificate(from: $0) }
        let certInfo = cert.map { Self.parse($0) }

        var findings: [WebScanResult.Finding] = []
        func check(_ title: String, _ header: String, recommend: String) {
            if let value = headers[header] {
                findings.append(.init(title: title, ok: true, detail: value))
            } else {
                findings.append(.init(title: title, ok: false, detail: "Ausente — \(recommend)"))
            }
        }
        findings.append(.init(title: "HTTPS",
                              ok: urlString.lowercased().hasPrefix("https"),
                              detail: urlString.lowercased().hasPrefix("https") ? "Conexão cifrada" : "Sem TLS"))
        check("HSTS", "strict-transport-security", recommend: "force HTTPS com Strict-Transport-Security")
        check("Content-Security-Policy", "content-security-policy", recommend: "defina uma CSP")
        check("X-Content-Type-Options", "x-content-type-options", recommend: "use 'nosniff'")
        check("X-Frame-Options", "x-frame-options", recommend: "evite clickjacking (DENY/SAMEORIGIN)")
        check("Referrer-Policy", "referrer-policy", recommend: "restrinja o referrer")
        check("Permissions-Policy", "permissions-policy", recommend: "restrinja APIs do navegador")

        if let notAfter = certInfo?.notAfter, notAfter < Date() {
            findings.append(.init(title: "Validade do certificado", ok: false, detail: "Certificado expirado"))
        } else if let notAfter = certInfo?.notAfter {
            let days = Int(notAfter.timeIntervalSinceNow / 86400)
            findings.append(.init(title: "Validade do certificado", ok: days > 14,
                                  detail: "Expira em \(days) dia(s)"))
        }

        return WebScanResult(
            url: urlString, statusCode: http.statusCode, server: headers["server"],
            certSubject: certInfo?.subject, certIssuer: certInfo?.issuer,
            certNotBefore: certInfo?.notBefore, certNotAfter: certInfo?.notAfter,
            presentHeaders: headers, findings: findings, error: nil
        )
    }

    private func empty(_ url: String, error: String) -> WebScanResult {
        WebScanResult(url: url, statusCode: nil, server: nil, certSubject: nil, certIssuer: nil,
                      certNotBefore: nil, certNotAfter: nil, presentHeaders: [:], findings: [], error: error)
    }

    // MARK: Captura de TLS

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            capturedTrust = trust
            // Validação padrão do sistema — não ignoramos erros de confiança.
            completionHandler(.performDefaultHandling, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    // MARK: Parse de certificado

    private static func leafCertificate(from trust: SecTrust) -> SecCertificate? {
        if #available(iOS 15.0, *) {
            return (SecTrustCopyCertificateChain(trust) as? [SecCertificate])?.first
        } else {
            return SecTrustGetCertificateAtIndex(trust, 0)
        }
    }

    private struct CertInfo { let subject: String?; let issuer: String?; let notBefore: Date?; let notAfter: Date? }

    private static func parse(_ cert: SecCertificate) -> CertInfo {
        // No iOS, a API pública expõe de forma confiável apenas o resumo do
        // titular. `SecCertificateCopyValues` e as constantes kSecOID* são
        // exclusivas do macOS. Emissor e datas de validade exigiriam parsing
        // manual de ASN.1/DER — não implementado nesta fase (não inventamos).
        let subject = SecCertificateCopySubjectSummary(cert) as String?
        return CertInfo(subject: subject, issuer: nil, notBefore: nil, notAfter: nil)
    }
}
