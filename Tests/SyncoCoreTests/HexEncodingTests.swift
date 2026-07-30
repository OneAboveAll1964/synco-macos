import XCTest
@testable import SyncoCore

final class HexEncodingTests: XCTestCase {
    private let bytes = Data([0x00, 0x0F, 0xA1, 0xB2, 0xFF])

    func testLowercaseEncoding() {
        XCTAssertEqual(HexEncoding.encode(bytes), "000fa1b2ff")
    }

    func testUppercaseEncoding() {
        XCTAssertEqual(HexEncoding.encode(bytes, uppercase: true), "000FA1B2FF")
    }

    func testDecodeAcceptsBothCases() throws {
        XCTAssertEqual(try HexEncoding.decode("000fa1b2ff"), bytes)
        XCTAssertEqual(try HexEncoding.decode("000FA1B2FF"), bytes)
    }

    func testRoundTrip() throws {
        let data = Data((0..<256).map { UInt8($0) })
        XCTAssertEqual(try HexEncoding.decode(HexEncoding.encode(data)), data)
    }

    func testOddLengthIsRejected() {
        XCTAssertThrowsError(try HexEncoding.decode("abc")) { error in
            XCTAssertEqual(error as? SyncoError, .invalidHexadecimal("abc"))
        }
    }

    func testNonHexadecimalIsRejected() {
        XCTAssertThrowsError(try HexEncoding.decode("zz"))
    }
}
