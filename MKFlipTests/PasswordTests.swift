import XCTest
@testable import MKFlip

final class PasswordTests: XCTestCase {

    func testEmptyPasswordIsVeryWeak() {
        let a = PasswordAnalyzer.audit("")
        XCTAssertEqual(a.strength, .veryWeak)
        XCTAssertEqual(a.entropyBits, 0)
    }

    func testCommonPasswordFlagged() {
        let a = PasswordAnalyzer.audit("123456")
        XCTAssertTrue(a.patterns.contains { $0.contains("comuns") })
        XCTAssertEqual(a.strength, .veryWeak)
    }

    func testStrongPasswordHasHighEntropy() {
        let a = PasswordAnalyzer.audit("G7!vQ2#mZ9xLp4@wR")
        XCTAssertGreaterThan(a.entropyBits, 60)
        XCTAssertTrue(a.strength == .strong || a.strength == .veryStrong)
    }

    func testPoolSizeReflectsCharacterClasses() {
        // minúscula + maiúscula + dígito + símbolo = 26+26+10+32 = 94
        let a = PasswordAnalyzer.audit("aA1!")
        XCTAssertEqual(a.poolSize, 94)
    }

    func testSequentialDetected() {
        let a = PasswordAnalyzer.audit("abc12345")
        XCTAssertTrue(a.patterns.contains { $0.contains("sequência") })
    }

    func testRepeatsDetected() {
        let a = PasswordAnalyzer.audit("aaabbbccc")
        XCTAssertTrue(a.patterns.contains { $0.contains("repetidos") })
    }

    func testRecommendationsAlwaysPresent() {
        XCTAssertFalse(PasswordAnalyzer.audit("qualquer").recommendations.isEmpty)
    }
}
