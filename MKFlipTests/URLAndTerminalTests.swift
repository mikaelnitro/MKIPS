import XCTest
@testable import MKFlip

final class URLAnalyzerTests: XCTestCase {

    func testHTTPSLowRisk() {
        let a = URLAnalyzer.analyze("https://apple.com")
        XCTAssertEqual(a.kind, .url)
        XCTAssertTrue(a.isHTTPS)
        XCTAssertEqual(a.riskLevel, .low)
    }

    func testHTTPFlaggedInsecure() {
        let a = URLAnalyzer.analyze("http://exemplo.com")
        XCTAssertTrue(a.riskSignals.contains { $0.contains("HTTP") })
    }

    func testShortenerDetected() {
        let a = URLAnalyzer.analyze("https://bit.ly/abcd")
        XCTAssertTrue(a.riskSignals.contains { $0.contains("Encurtador") })
    }

    func testIPHostDetected() {
        let a = URLAnalyzer.analyze("http://192.168.0.1/login")
        XCTAssertTrue(a.riskSignals.contains { $0.contains("IP") })
    }

    func testWifiClassification() {
        XCTAssertEqual(URLAnalyzer.classify("WIFI:S:MinhaRede;T:WPA;P:senha;;"), .wifi)
    }

    func testPlainTextClassification() {
        XCTAssertEqual(URLAnalyzer.classify("apenas um texto"), .text)
    }
}

final class TerminalEngineTests: XCTestCase {

    func testHashCommand() {
        let r = TerminalEngine.run("hash sha256 abc")
        XCTAssertEqual(r.lines.first?.0,
                       "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testHashCommandBadUsage() {
        let r = TerminalEngine.run("hash")
        XCTAssertEqual(r.lines.first?.1, .error)
    }

    func testClearSetsFlag() {
        XCTAssertTrue(TerminalEngine.run("clear").clearScreen)
    }

    func testUnknownCommandErrors() {
        XCTAssertEqual(TerminalEngine.run("foobar").lines.first?.1, .error)
    }

    func testOpenNavigates() {
        XCTAssertEqual(TerminalEngine.run("open crypto").navigateTo, .cryptography)
    }

    func testB64EncDecRoundTripViaCommands() {
        let enc = TerminalEngine.run("b64enc hello").lines.first!.0
        let dec = TerminalEngine.run("b64dec \(enc)").lines.first!.0
        XCTAssertEqual(dec, "hello")
    }

    func testPwcheckDoesNotEchoPassword() {
        let r = TerminalEngine.run("pwcheck SuperSecret123")
        XCTAssertFalse(r.lines.contains { $0.0.contains("SuperSecret123") })
    }

    func testHelpListsCommands() {
        XCTAssertGreaterThan(TerminalEngine.run("help").lines.count, 5)
    }
}
