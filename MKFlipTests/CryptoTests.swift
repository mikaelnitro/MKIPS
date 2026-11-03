import XCTest
@testable import MKFlip

final class CryptoTests: XCTestCase {

    func testSHA256KnownVector() {
        // "abc" → vetor conhecido do NIST.
        XCTAssertEqual(HashEngine.hash("abc", with: .sha256),
                       "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testSHA512KnownVector() {
        XCTAssertEqual(HashEngine.hash("abc", with: .sha512),
                       "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a"
                     + "2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f")
    }

    func testMD5KnownVector() {
        XCTAssertEqual(HashEngine.hash("abc", with: .md5), "900150983cd24fb0d6963f7d28e17f72")
    }

    func testDigestReturnsAllAlgorithms() {
        let digest = HashEngine.digest(Data("x".utf8))
        XCTAssertEqual(digest.count, HashAlgorithm.allCases.count)
    }

    func testBase64RoundTrip() {
        let original = "MK FLIP — Cyber"
        let encoded = EncodingTools.base64Encode(original)
        XCTAssertEqual(EncodingTools.base64Decode(encoded), original)
    }

    func testBase64InvalidReturnsNil() {
        XCTAssertNil(EncodingTools.base64Decode("@@@não-é-base64@@@"))
    }

    func testHexRoundTrip() {
        let original = "hex123"
        XCTAssertEqual(EncodingTools.hexDecode(EncodingTools.hexEncode(original)), original)
    }

    func testHexEncodeKnown() {
        XCTAssertEqual(EncodingTools.hexEncode("AB"), "4142")
    }

    func testHashIdentifierSHA256() {
        let sha = HashEngine.hash("abc", with: .sha256)
        XCTAssertTrue(HashIdentifier.identify(sha).contains { $0.name == "SHA-256" })
    }

    func testHashIdentifierMD5Length() {
        XCTAssertTrue(HashIdentifier.identify(String(repeating: "a", count: 32))
            .contains { $0.name == "MD5" })
    }

    func testHashIdentifierBcrypt() {
        XCTAssertTrue(HashIdentifier.identify("$2b$12$abcdefghijklmnopqrstuv")
            .contains { $0.name == "bcrypt" })
    }
}
