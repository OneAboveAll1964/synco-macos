import XCTest
@testable import SyncoCore

final class DeviceIdentifierTests: XCTestCase {
    func testValidDeviceIDIsAccepted() throws {
        let identifier = try DeviceID(validating: "abcdefghij234567")
        XCTAssertEqual(identifier.rawValue, "abcdefghij234567")
    }

    func testWrongLengthIsRejected() {
        XCTAssertThrowsError(try DeviceID(validating: "abcdefghij23456"))
        XCTAssertThrowsError(try DeviceID(validating: "abcdefghij2345678"))
    }

    func testNonAlphabetCharactersAreRejected() {
        XCTAssertThrowsError(try DeviceID(validating: "ABCDEFGHIJ234567"))
        XCTAssertThrowsError(try DeviceID(validating: "abcdefghij234560"))
        XCTAssertThrowsError(try DeviceID(validating: "abcdefghij23456-"))
    }

    func testInitiatorIsTheSmallerDeviceID() throws {
        let lower = try DeviceID(validating: "aaaaaaaaaaaaaaaa")
        let upper = try DeviceID(validating: "aaaaaaaaaaaaaaab")
        XCTAssertTrue(lower.isInitiator(against: upper))
        XCTAssertFalse(upper.isInitiator(against: lower))
        XCTAssertTrue(lower < upper)
    }

    func testDigitsSortBeforeLettersAsInASCII() throws {
        let letters = try DeviceID(validating: "zzzzzzzzzzzzzzzz")
        let digits = try DeviceID(validating: "2222222222222222")
        XCTAssertTrue(digits < letters)
    }

    func testDeviceIDCodesAsBareString() throws {
        let identifier = try DeviceID(validating: "abcdefghij234567")
        let encoded = try JSONEncoder().encode([identifier])
        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), "[\"abcdefghij234567\"]")
        XCTAssertEqual(try JSONDecoder().decode([DeviceID].self, from: encoded), [identifier])
    }

    func testInvalidDeviceIDFailsDecoding() {
        let payload = Data("[\"nope\"]".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode([DeviceID].self, from: payload))
    }

    func testFingerprintGrouping() throws {
        let fingerprint = try Fingerprint(digestPrefix: Data([0xA1, 0xB2, 0xC3, 0xD4, 0xE5, 0xF6, 0x07, 0x18]))
        XCTAssertEqual(fingerprint.compact, "A1B2C3D4E5F60718")
        XCTAssertEqual(fingerprint.grouped, "A1B2-C3D4-E5F6-0718")
    }

    func testFingerprintParsesGroupedAndCompactForms() throws {
        let grouped = try Fingerprint(parsing: "A1B2-C3D4-E5F6-0718")
        let compact = try Fingerprint(parsing: "a1b2c3d4e5f60718")
        XCTAssertEqual(grouped, compact)
    }

    func testFingerprintCodesAsGroupedString() throws {
        let fingerprint = try Fingerprint(parsing: "A1B2-C3D4-E5F6-0718")
        let encoded = try JSONEncoder().encode([fingerprint])
        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), "[\"A1B2-C3D4-E5F6-0718\"]")
        XCTAssertEqual(try JSONDecoder().decode([Fingerprint].self, from: encoded), [fingerprint])
    }

    func testFingerprintRejectsWrongLength() {
        XCTAssertThrowsError(try Fingerprint(parsing: "A1B2-C3D4-E5F6"))
        XCTAssertThrowsError(try Fingerprint(digestPrefix: Data([0x01, 0x02])))
    }
}
