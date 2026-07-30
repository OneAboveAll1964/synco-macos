import SyncoCore
import XCTest
@testable import SyncoCrypto

final class HandshakeTests: XCTestCase {
    func testBothSidesDeriveIdenticalKeys() throws {
        let session = try HandshakeSessionPair()
        XCTAssertEqual(session.initiatorResult.sendKey, session.responderResult.receiveKey)
        XCTAssertEqual(session.initiatorResult.receiveKey, session.responderResult.sendKey)
        XCTAssertNotEqual(session.initiatorResult.sendKey, session.initiatorResult.receiveKey)
        XCTAssertEqual(session.initiatorResult.sendKey.count, SyncoConstants.Handshake.sessionKeyBytes)
        XCTAssertEqual(session.initiatorResult.receiveKey.count, SyncoConstants.Handshake.sessionKeyBytes)
    }

    func testBothSidesVerifyEachOthersConfirmationTag() throws {
        let session = try HandshakeSessionPair()
        XCTAssertTrue(session.responderResult.verifyPeerConfirmationTag(session.initiatorResult.confirmationTag))
        XCTAssertTrue(session.initiatorResult.verifyPeerConfirmationTag(session.responderResult.confirmationTag))
        XCTAssertNoThrow(
            try session.initiatorResult.requirePeerConfirmationTag(session.responderResult.confirmationTag)
        )
        XCTAssertEqual(
            session.initiatorResult.confirmationTag.count,
            SyncoConstants.Handshake.confirmationTagBytes
        )
    }

    func testAuthMessageCarriesTheConfirmationTag() throws {
        let session = try HandshakeSessionPair()
        XCTAssertEqual(session.initiatorResult.authMessage.tag, session.initiatorResult.confirmationTag)
    }

    func testTamperedConfirmationTagIsRejected() throws {
        let session = try HandshakeSessionPair()
        var tampered = session.initiatorResult.confirmationTag
        tampered[0] ^= 0x01
        XCTAssertFalse(session.responderResult.verifyPeerConfirmationTag(tampered))
        XCTAssertThrowsError(try session.responderResult.requirePeerConfirmationTag(tampered)) { error in
            XCTAssertEqual(error as? SyncoError, .badAuth)
        }
    }

    func testTruncatedConfirmationTagIsRejected() throws {
        let session = try HandshakeSessionPair()
        let truncated = Data(session.initiatorResult.confirmationTag.dropLast())
        XCTAssertFalse(session.responderResult.verifyPeerConfirmationTag(truncated))
    }

    func testOwnTagIsNotAcceptedAsThePeerTag() throws {
        let session = try HandshakeSessionPair()
        XCTAssertFalse(session.initiatorResult.verifyPeerConfirmationTag(session.initiatorResult.confirmationTag))
    }

    func testTransposedRoleProducesDifferentKeys() throws {
        let session = try HandshakeSessionPair()
        let transposed = try Handshake.derive(
            role: .initiator,
            identity: session.responder,
            ephemeral: session.responderEphemeral,
            peerDeviceID: session.initiator.deviceID,
            peerStaticPublicKey: session.initiator.publicKey,
            peerEphemeralPublicKey: session.initiatorEphemeral.publicKey
        )
        XCTAssertNotEqual(transposed.sendKey, session.responderResult.sendKey)
        XCTAssertFalse(session.initiatorResult.verifyPeerConfirmationTag(transposed.confirmationTag))
    }

    func testSaltIsIndependentOfRole() throws {
        let session = try HandshakeSessionPair()
        XCTAssertEqual(
            Handshake.salt(localDeviceID: session.initiator.deviceID, peerDeviceID: session.responder.deviceID),
            Handshake.salt(localDeviceID: session.responder.deviceID, peerDeviceID: session.initiator.deviceID)
        )
    }

    func testRoleFollowsDeviceIDOrdering() throws {
        let lower = try DeviceID(validating: "aaaaaaaaaaaaaaaa")
        let upper = try DeviceID(validating: "bbbbbbbbbbbbbbbb")
        XCTAssertEqual(HandshakeRole.role(localDeviceID: lower, peerDeviceID: upper), .initiator)
        XCTAssertEqual(HandshakeRole.role(localDeviceID: upper, peerDeviceID: lower), .responder)
        XCTAssertEqual(HandshakeRole.initiator.peerRole, .responder)
    }

    func testWrongPeerStaticKeyBreaksConfirmation() throws {
        let session = try HandshakeSessionPair()
        let impostor = try DeviceIdentity.generate()
        let derived = try Handshake.derive(
            role: .responder,
            identity: session.responder,
            ephemeral: session.responderEphemeral,
            peerDeviceID: session.initiator.deviceID,
            peerStaticPublicKey: impostor.publicKey,
            peerEphemeralPublicKey: session.initiatorEphemeral.publicKey
        )
        XCTAssertFalse(derived.verifyPeerConfirmationTag(session.initiatorResult.confirmationTag))
    }

    func testAllZeroPeerEphemeralKeyAborts() throws {
        let session = try HandshakeSessionPair()
        XCTAssertThrowsError(
            try Handshake.derive(
                role: .initiator,
                identity: session.initiator,
                ephemeral: session.initiatorEphemeral,
                peerDeviceID: session.responder.deviceID,
                peerStaticPublicKey: session.responder.publicKey,
                peerEphemeralPublicKey: Data(repeating: 0, count: SyncoConstants.Identity.publicKeyBytes)
            )
        ) { error in
            XCTAssertEqual(error as? SyncoError, .badHandshake)
        }
    }
}
