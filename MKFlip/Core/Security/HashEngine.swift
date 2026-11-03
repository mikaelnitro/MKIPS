import Foundation
import CryptoKit

/// Funções de resumo criptográfico. Usa CryptoKit (acelerado por hardware no
/// iPhone). SHA-256/384/512 são recomendados; MD5/SHA-1 são oferecidos apenas
/// para *verificação/identificação* de artefatos legados, nunca para segurança.
enum HashAlgorithm: String, CaseIterable, Identifiable, Sendable {
    case md5 = "MD5"
    case sha1 = "SHA-1"
    case sha256 = "SHA-256"
    case sha384 = "SHA-384"
    case sha512 = "SHA-512"

    var id: String { rawValue }

    /// Marca algoritmos quebrados para colisão (aviso na UI).
    var isLegacy: Bool { self == .md5 || self == .sha1 }
}

enum HashEngine {

    /// Hash de dados arbitrários, retornado em hex minúsculo.
    static func hash(_ data: Data, with algorithm: HashAlgorithm) -> String {
        switch algorithm {
        case .md5:    Insecure.MD5.hash(data: data).hex
        case .sha1:   Insecure.SHA1.hash(data: data).hex
        case .sha256: SHA256.hash(data: data).hex
        case .sha384: SHA384.hash(data: data).hex
        case .sha512: SHA512.hash(data: data).hex
        }
    }

    /// Hash de texto UTF-8.
    static func hash(_ text: String, with algorithm: HashAlgorithm) -> String {
        hash(Data(text.utf8), with: algorithm)
    }

    /// Todos os algoritmos de uma vez — para a aba "resumo" do Crypto Lab.
    static func digest(_ data: Data) -> [(HashAlgorithm, String)] {
        HashAlgorithm.allCases.map { ($0, hash(data, with: $0)) }
    }
}

extension Sequence where Element == UInt8 {
    /// Representação hexadecimal minúscula de uma sequência de bytes.
    var hex: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
