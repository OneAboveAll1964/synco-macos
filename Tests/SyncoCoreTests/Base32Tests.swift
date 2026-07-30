import XCTest
@testable import SyncoCore

final class Base32Tests: XCTestCase {
    private let vectors: [(String, String)] = [
        ("", ""),
        ("f", "my"),
        ("fo", "mzxq"),
        ("foo", "mzxw6"),
        ("foob", "mzxw6yq"),
        ("fooba", "mzxw6ytb"),
        ("foobar", "mzxw6ytboi"),
    ]

    func testEncodeMatchesKnownVectors() {
        for (plain, encoded) in vectors {
            XCTAssertEqual(Base32.encode(Data(plain.utf8)), encoded)
        }
    }

    func testDecodeMatchesKnownVectors() throws {
        for (plain, encoded) in vectors {
            XCTAssertEqual(try Base32.decode(encoded), Data(plain.utf8))
        }
    }

    func testRoundTripAcrossAllLengths() throws {
        for length in 0...40 {
            let data = Data((0..<length).map { UInt8(($0 * 31 + 7) % 256) })
            XCTAssertEqual(try Base32.decode(Base32.encode(data)), data)
        }
    }

    func testTenBytesEncodeToSixteenCharacters() {
        let data = Data(repeating: 0xAB, count: SyncoConstants.Identity.deviceIDDigestPrefixBytes)
        XCTAssertEqual(Base32.encode(data).count, SyncoConstants.Identity.deviceIDCharacters)
    }

    func testPaddingIsRejected() {
        XCTAssertThrowsError(try Base32.decode("my======")) { error in
            XCTAssertEqual(error as? SyncoError, .invalidBase32("my======"))
        }
    }

    func testInvalidSymbolIsRejected() {
        XCTAssertThrowsError(try Base32.decode("mzxw61"))
        XCTAssertThrowsError(try Base32.decode("mzxw6!"))
    }

    func testInvalidLengthIsRejected() {
        XCTAssertThrowsError(try Base32.decode("m"))
        XCTAssertThrowsError(try Base32.decode("mzx"))
        XCTAssertThrowsError(try Base32.decode("mzxw6y"))
    }

    func testNonZeroResidueBitsAreRejected() {
        XCTAssertThrowsError(try Base32.decode("mz"))
    }
}
