import XCTest
@testable import MKFlip

final class RedactionTests: XCTestCase {

    func testPwcheckArgumentIsMasked() {
        let out = LogRedactor.redactCommand("pwcheck MinhaSenha123")
        XCTAssertTrue(out.hasPrefix("pwcheck "))
        XCTAssertFalse(out.contains("MinhaSenha123"), "A senha não pode aparecer no log")
    }

    func testNonSensitiveCommandUnchanged() {
        XCTAssertEqual(LogRedactor.redactCommand("hash sha256 abc"), "hash sha256 abc")
    }

    func testBearerTokenRedacted() {
        let out = LogRedactor.redactText("Authorization: Bearer sk-abc123DEF456")
        XCTAssertFalse(out.contains("sk-abc123DEF456"))
    }

    func testKeyValueSecretRedacted() {
        let out = LogRedactor.redactText("api_key=supersecretvalue")
        XCTAssertFalse(out.contains("supersecretvalue"))
    }

    func testEmptyStaysEmpty() {
        XCTAssertEqual(LogRedactor.redactCommand("   "), "")
    }
}
