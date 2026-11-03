import Foundation
import Observation
#if canImport(CoreNFC)
import CoreNFC
#endif

/// Leitura resultante de uma tag NFC.
struct NFCReading: Identifiable, Sendable {
    let id = UUID()
    let timestamp = Date()
    let technology: String
    let identifier: String        // UID em hex
    let extra: [String: String]   // campos específicos da tecnologia
    let ndefRecords: [String]     // payloads NDEF decodificados
}

/// Leitor NFC baseado em `NFCTagReaderSession`. Identifica a tecnologia e o UID
/// e tenta ler NDEF. Não clona nada e não lê cartões de pagamento/credenciais —
/// o iOS tão pouco permite, e o app não tenta.
@MainActor
@Observable
final class NFCReader: NSObject {
    var readings: [NFCReading] = []
    var statusMessage: String = ""
    var isAvailable: Bool = false

    #if canImport(CoreNFC)
    private var session: NFCTagReaderSession?

    override init() {
        super.init()
        isAvailable = NFCTagReaderSession.readingAvailable
    }

    func beginScan() {
        guard NFCTagReaderSession.readingAvailable else {
            statusMessage = "NFC indisponível neste dispositivo."
            return
        }
        session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092],
                                      delegate: self, queue: nil)
        session?.alertMessage = "Aproxime uma tag NFC compatível."
        session?.begin()
    }
    #else
    override init() {
        super.init()
        isAvailable = false
        statusMessage = "Core NFC não disponível nesta plataforma."
    }
    func beginScan() { statusMessage = "Core NFC não disponível nesta plataforma." }
    #endif
}

#if canImport(CoreNFC)
extension NFCReader: NFCTagReaderSessionDelegate {

    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            self.statusMessage = "Sessão encerrada: \(error.localizedDescription)"
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }
        session.connect(to: tag) { [weak self] error in
            if let error {
                session.invalidate(errorMessage: "Falha ao conectar: \(error.localizedDescription)")
                return
            }
            self?.handle(tag, session: session)
        }
    }

    private nonisolated func handle(_ tag: NFCTag, session: NFCTagReaderSession) {
        var tech = "Desconhecida"
        var uid = "—"
        var extra: [String: String] = [:]

        switch tag {
        case .miFare(let mifare):
            tech = "MIFARE / ISO14443"
            uid = mifare.identifier.hexString
            extra["Família"] = "\(mifare.mifareFamily.rawValue)"
        case .iso7816(let iso):
            tech = "ISO7816"
            uid = iso.identifier.hexString
            if let aid = iso.initialSelectedAID as String? { extra["AID"] = aid }
        case .iso15693(let iso):
            tech = "ISO15693"
            uid = iso.identifier.hexString
        case .feliCa(let felica):
            tech = "FeliCa"
            uid = felica.currentIDm.hexString
        @unknown default:
            tech = "Não suportada"
        }

        // Tenta ler NDEF, quando a tag suportar. (Já conectado em didDetect.)
        self.readNDEF(from: tag) { records in
            let reading = NFCReading(technology: tech, identifier: uid, extra: extra, ndefRecords: records)
            Task { @MainActor in
                self.readings.insert(reading, at: 0)
                self.statusMessage = "Tag lida: \(tech)"
            }
            session.alertMessage = "Leitura concluída."
            session.invalidate()
        }
    }

    private nonisolated func readNDEF(from tag: NFCTag, completion: @escaping ([String]) -> Void) {
        var ndefTag: NFCNDEFTag?
        switch tag {
        case .miFare(let t): ndefTag = t
        case .iso7816(let t): ndefTag = t
        case .iso15693(let t): ndefTag = t
        case .feliCa(let t): ndefTag = t
        @unknown default: break
        }
        guard let ndefTag else { completion([]); return }

        ndefTag.queryNDEFStatus { status, _, error in
            guard error == nil, status != .notSupported else { completion([]); return }
            ndefTag.readNDEF { message, _ in
                guard let message else { completion([]); return }
                let records = message.records.map { record -> String in
                    let payload = String(data: record.payload, encoding: .utf8)
                        ?? record.payload.hexString
                    let type = String(data: record.type, encoding: .utf8) ?? "?"
                    return "[\(type)] \(payload)"
                }
                completion(records)
            }
        }
    }
}

private extension Data {
    var hexString: String { map { String(format: "%02X", $0) }.joined(separator: " ") }
}
#endif
