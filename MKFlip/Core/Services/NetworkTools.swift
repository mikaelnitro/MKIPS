import Foundation
import Network
import Observation

/// Ferramentas de diagnóstico de rede reais, respeitando as restrições do iOS.
/// Nada de varredura de terceiros não autorizados — operações pontuais sobre
/// hosts informados pelo usuário.
actor NetworkTools {

    // MARK: DNS

    struct DNSResult: Sendable {
        let host: String
        let addresses: [String]
        let error: String?
    }

    /// Resolve A/AAAA via `getaddrinfo` (POSIX, disponível no iOS).
    func resolve(_ host: String) -> DNSResult {
        let clean = sanitizeHost(host)
        guard !clean.isEmpty else { return DNSResult(host: host, addresses: [], error: "Host vazio") }

        var hints = addrinfo(ai_flags: 0, ai_family: AF_UNSPEC,
                             ai_socktype: SOCK_STREAM, ai_protocol: 0,
                             ai_addrlen: 0, ai_canonname: nil, ai_addr: nil, ai_next: nil)
        var info: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(clean, nil, &hints, &info)
        guard status == 0, let first = info else {
            return DNSResult(host: clean, addresses: [], error: String(cString: gai_strerror(status)))
        }
        defer { freeaddrinfo(info) }

        var addresses: [String] = []
        var ptr: UnsafeMutablePointer<addrinfo>? = first
        while let current = ptr {
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(current.pointee.ai_addr, current.pointee.ai_addrlen,
                           &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 {
                let addr = String(cString: buffer)
                if !addresses.contains(addr) { addresses.append(addr) }
            }
            ptr = current.pointee.ai_next
        }
        return DNSResult(host: clean, addresses: addresses, error: addresses.isEmpty ? "Sem registros" : nil)
    }

    // MARK: Verificação de porta / disponibilidade

    enum PortStatus: String, Sendable { case open = "Aberta", closed = "Fechada", timeout = "Timeout" }

    /// Tenta um handshake TCP. Retorna o estado observável em até `timeout` s.
    func checkPort(_ host: String, port: UInt16, timeout: TimeInterval = 4) async -> PortStatus {
        let clean = sanitizeHost(host)
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return .closed }

        let connection = NWConnection(host: NWEndpoint.Host(clean), port: nwPort, using: .tcp)

        return await withCheckedContinuation { continuation in
            let done = Atomic()
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if done.set() { connection.cancel(); continuation.resume(returning: .open) }
                case .failed, .cancelled:
                    if done.set() { connection.cancel(); continuation.resume(returning: .closed) }
                default: break
                }
            }
            connection.start(queue: .global())
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if done.set() { connection.cancel(); continuation.resume(returning: .timeout) }
            }
        }
    }

    private func sanitizeHost(_ raw: String) -> String {
        var h = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let comps = URLComponents(string: h), let host = comps.host { h = host }
        h = h.replacingOccurrences(of: "https://", with: "")
             .replacingOccurrences(of: "http://", with: "")
        if let slash = h.firstIndex(of: "/") { h = String(h[..<slash]) }
        return h
    }
}

/// Pequeno guard de resumo único para a continuation (evita dupla chamada).
private final class Atomic: @unchecked Sendable {
    private let lock = NSLock()
    private var fired = false
    func set() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if fired { return false }
        fired = true
        return true
    }
}

/// Observador do caminho de rede atual (tipo de interface, status).
@MainActor
@Observable
final class ConnectionMonitor {
    var isConnected = false
    var interface = "—"
    var isExpensive = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "mkflip.netmonitor")

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.interface = Self.describe(path)
            }
        }
        monitor.start(queue: queue)
    }

    func stop() { monitor.cancel() }

    private static func describe(_ path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) { return "Wi-Fi" }
        if path.usesInterfaceType(.cellular) { return "Celular" }
        if path.usesInterfaceType(.wiredEthernet) { return "Ethernet" }
        if path.usesInterfaceType(.loopback) { return "Loopback" }
        return path.status == .satisfied ? "Outra" : "Offline"
    }
}
