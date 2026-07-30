import SyncoCore
import XCTest
@testable import SyncoCrypto

final class CryptoPrimitivesTests: XCTestCase {
    func testHKDFMatchesRFC5869TestCase1() throws {
        let ikm = Data(repeating: 0x0B, count: 22)
        let salt = try HexEncoding.decode("000102030405060708090a0b0c")
        let info = try HexEncoding.decode("f0f1f2f3f4f5f6f7f8f9")
        let okm = CryptoPrimitives.hkdfSHA256(ikm: ikm, salt: salt, info: info, length: 42)
        XCTAssertEqual(
            HexEncoding.encode(okm),
            "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865"
        )
    }

    func testSHA256MatchesKnownDigest() {
        XCTAssertEqual(
            HexEncoding.encode(CryptoPrimitives.sha256(Data("abc".utf8))),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    func testHMACMatchesRFC4231TestCase2() {
        let tag = CryptoPrimitives.hmacSHA256(key: Data("Jefe".utf8), message: Data("what do ya want for nothing?".utf8))
        XCTAssertEqual(
            HexEncoding.encode(tag),
            "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843"
        )
    }

    func testConstantTimeEqualsMatchesValueEquality() {
        let left = Data([0x01, 0x02, 0x03])
        XCTAssertTrue(CryptoPrimitives.constantTimeEquals(left, Data([0x01, 0x02, 0x03])))
        XCTAssertFalse(CryptoPrimitives.constantTimeEquals(left, Data([0x01, 0x02, 0x04])))
        XCTAssertFalse(CryptoPrimitives.constantTimeEquals(left, Data([0x01, 0x02])))
        XCTAssertTrue(CryptoPrimitives.constantTimeEquals(Data(), Data()))
    }

    func testRandomBytesLengthAndVariation() {
        let first = CryptoPrimitives.randomBytes(32)
        let second = CryptoPrimitives.randomBytes(32)
        XCTAssertEqual(first.count, 32)
        XCTAssertEqual(second.count, 32)
        XCTAssertNotEqual(first, second)
    }

    func testKeyAgreementIsSymmetric() throws {
        let left = EphemeralKeyPair.generate()
        let right = EphemeralKeyPair.generate()
        let fromLeft = try CryptoPrimitives.keyAgreement(privateKey: left.privateKey, peerPublicKey: right.publicKey)
        let fromRight = try CryptoPrimitives.keyAgreement(privateKey: right.privateKey, peerPublicKey: left.publicKey)
        XCTAssertEqual(fromLeft, fromRight)
        XCTAssertEqual(fromLeft.count, SyncoConstants.Handshake.sharedSecretBytes)
    }

    func testKeyAgreementRejectsLowOrderPoint() {
        let pair = EphemeralKeyPair.generate()
        let allZeroPoint = Data(repeating: 0, count: SyncoConstants.Identity.publicKeyBytes)
        XCTAssertThrowsError(
            try CryptoPrimitives.keyAgreement(privateKey: pair.privateKey, peerPublicKey: allZeroPoint)
        ) { error in
            XCTAssertEqual(error as? SyncoError, .badHandshake)
        }
    }

    func testKeyAgreementRejectsMalformedPeerKey() {
        let pair = EphemeralKeyPair.generate()
        XCTAssertThrowsError(
            try CryptoPrimitives.keyAgreement(privateKey: pair.privateKey, peerPublicKey: Data([0x01]))
        ) { error in
            XCTAssertEqual(error as? SyncoError, .badHandshake)
        }
    }
}
