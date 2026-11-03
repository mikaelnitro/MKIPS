import Foundation
import CryptoKit

/// Geração de material criptográfico de **demonstração** (didático).
/// Deixa claro na UI que não substitui gestão de chaves em produção.
enum KeyGenerator {

    /// Bytes aleatórios seguros em hex.
    static func randomBytes(count: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: max(1, count))
        for i in bytes.indices { bytes[i] = UInt8.random(in: 0...255) }
        return bytes.hex
    }

    /// Chave simétrica (AES) de demonstração, em Base64.
    static func symmetricKeyBase64(bits: Int = 256) -> String {
        let size: SymmetricKeySize = bits == 128 ? .bits128 : (bits == 192 ? .bits192 : .bits256)
        let key = SymmetricKey(size: size)
        return key.withUnsafeBytes { Data($0).base64EncodedString() }
    }

    /// Par de chaves Curve25519 de demonstração (chave pública/privada em Base64).
    static func curve25519Pair() -> (privateKey: String, publicKey: String) {
        let priv = Curve25519.Signing.PrivateKey()
        return (priv.rawRepresentation.base64EncodedString(),
                priv.publicKey.rawRepresentation.base64EncodedString())
    }
}
