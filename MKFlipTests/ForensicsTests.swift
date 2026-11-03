import XCTest
@testable import MKFlip

final class ForensicsTests: XCTestCase {

    func testDetectPNG() {
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00])
        XCTAssertEqual(FileSignature.detect(png)?.name, "PNG")
    }

    func testDetectJPEG() {
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00])
        XCTAssertEqual(FileSignature.detect(jpeg)?.name, "JPEG")
    }

    func testDetectPDF() {
        XCTAssertEqual(FileSignature.detect(Data("%PDF-1.7".utf8))?.name, "PDF")
    }

    func testUnknownReturnsNil() {
        XCTAssertNil(FileSignature.detect(Data([0x01, 0x02, 0x03, 0x04])))
    }

    func testExtensionMismatchDetected() {
        // bytes de PNG, mas nome diz .jpg
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        let a = ForensicsAnalyzer.analyze(data: png, name: "foto.jpg")
        XCTAssertTrue(a.declaredVsDetectedMismatch)
    }

    func testStringsExtraction() {
        let data = Data([0x00, 0x48, 0x45, 0x4C, 0x4C, 0x4F, 0x00])  // "HELLO"
        XCTAssertTrue(StringsExtractor.extract(from: data, minLength: 4).contains("HELLO"))
    }

    func testInterestingStringsFlagURLs() {
        let found = StringsExtractor.interesting(["http://evil.test/x", "banana"])
        XCTAssertEqual(found, ["http://evil.test/x"])
    }

    func testEntropyOfUniformDataIsLow() {
        let zeros = Data(repeating: 0, count: 1000)
        XCTAssertEqual(ForensicsAnalyzer.shannonEntropy(zeros), 0, accuracy: 0.0001)
    }

    func testHexDumpFormatsOffset() {
        let lines = HexDump.lines(from: Data([0x41, 0x42]))
        XCTAssertTrue(lines.first?.hasPrefix("00000000") ?? false)
        XCTAssertTrue(lines.first?.contains("|AB|") ?? false)
    }

    func testFileComparatorIdentical() {
        let a = Data("same".utf8)
        let r = FileComparator.compare(a, a)
        XCTAssertTrue(r.identical)
        XCTAssertNil(r.firstDiffOffset)
    }

    func testFileComparatorFindsFirstDiff() {
        let r = FileComparator.compare(Data("abcX".utf8), Data("abcY".utf8))
        XCTAssertFalse(r.identical)
        XCTAssertEqual(r.firstDiffOffset, 3)
        XCTAssertEqual(r.sameLeadingBytes, 3)
    }
}
