import SyncoCore
import XCTest
@testable import SyncoCrypto

final class DeviceIdentityTests: XCTestCase {
    private let publicKey = Data((0..<32).map { UInt8($0) })

    func testDeviceIDDerivationMatchesSpecification() throws {
        let derived = try DeviceIdentity.deviceID(forStaticPublicKey: publicKey)
        XCTAssertEqual(derived.rawValue, "mmg42klgyqzwneis")
    }

    func testFingerprintDerivationMatchesSpecification() throws {
        let fingerprint = try DeviceIdentity.fingerprint(forStaticPublicKey: publicKey)
        XCTAssertEqual(fingerprint.compact, "630DCD2966C43366")
        XCTAssertEqual(fingerprint.grouped, "630D-CD29-66C4-3366")
    }

    func testDerivationUsesTheFirstTenAndEightDigestBytes() {
        let digest = CryptoPrimitives.sha256(publicKey)
        XCTAssertEqual(
            HexEncoding.encode(digest),
            "630dcd2966c4336691125448bbb25b4ff412a49c732db2c8abc1b8581bd710dd"
        )
        XCTAssertEqual(Base32.encode(Data(digest.prefix(10))), "mmg42klgyqzwneis")
        XCTAssertEqual(HexEncoding.encode(Data(digest.prefix(8)), uppercase: true), "630DCD2966C43366")
    }

    func testGeneratedIdentityIsSelfConsistent() throws {
        let identity = try DeviceIdentity.generate()
        XCTAssertEqual(identity.publicKey.count, SyncoConstants.Identity.publicKeyBytes)
        XCTAssertEqual(identity.deviceID.rawValue.count, SyncoConstants.Identity.deviceIDCharacters)
        XCTAssertEqual(try DeviceIdentity.deviceID(forStaticPublicKey: identity.publicKey), identity.deviceID)
        XCTAssertEqual(try DeviceIdentity.fingerprint(forStaticPublicKey: identity.publicKey), identity.fingerprint)
        XCTAssertTrue(DeviceIdentity.staticPublicKey(identity.publicKey, matches: identity.deviceID))
    }

    func testGeneratedIdentitiesAreDistinct() throws {
        let first = try DeviceIdentity.generate()
        let second = try DeviceIdentity.generate()
        XCTAssertNotEqual(first.deviceID, second.deviceID)
        XCTAssertNotEqual(first.publicKey, second.publicKey)
    }

    func testMismatchedStaticKeyIsDetected() throws {
        let identity = try DeviceIdentity.generate()
        let other = try DeviceIdentity.generate()
        XCTAssertFalse(DeviceIdentity.staticPublicKey(other.publicKey, matches: identity.deviceID))
        XCTAssertFalse(DeviceIdentity.staticPublicKey(Data([0x01, 0x02]), matches: identity.deviceID))
    }

    func testInvalidPrivateKeyLengthIsRejected() {
        XCTAssertThrowsError(try DeviceIdentity(privateKeyRepresentation: Data([0x01, 0x02]))) { error in
            XCTAssertEqual(error as? SyncoError, .invalidIdentityKey)
        }
    }

    func testEphemeralKeyPairsAreNeverReused() {
        let keys = (0..<8).map { _ in EphemeralKeyPair.generate().publicKey }
        XCTAssertEqual(Set(keys).count, keys.count)
        XCTAssertTrue(keys.allSatisfy { $0.count == SyncoConstants.Identity.publicKeyBytes })
    }
}
