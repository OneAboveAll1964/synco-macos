import SyncoCore
import XCTest
@testable import SyncoCrypto

final class HandshakeVectorTests: XCTestCase {
    func testFixedKeysProduceTheExpectedPublicKeysAndDeviceIDs() throws {
        let identityA = try HandshakeVector.identity(HandshakeVector.staticPrivateKeyA)
        let identityB = try HandshakeVector.identity(HandshakeVector.staticPrivateKeyB)
        let ephemeralA = try HandshakeVector.ephemeral(HandshakeVector.ephemeralPrivateKeyA)
        let ephemeralB = try HandshakeVector.ephemeral(HandshakeVector.ephemeralPrivateKeyB)
        XCTAssertEqual(HexEncoding.encode(identityA.publicKey), HandshakeVector.staticPublicKeyA)
        XCTAssertEqual(HexEncoding.encode(identityB.publicKey), HandshakeVector.staticPublicKeyB)
        XCTAssertEqual(HexEncoding.encode(ephemeralA.publicKey), HandshakeVector.ephemeralPublicKeyA)
        XCTAssertEqual(HexEncoding.encode(ephemeralB.publicKey), HandshakeVector.ephemeralPublicKeyB)
        XCTAssertEqual(identityA.deviceID.rawValue, HandshakeVector.deviceIDA)
        XCTAssertEqual(identityB.deviceID.rawValue, HandshakeVector.deviceIDB)
    }

    func testFixedKeysProduceTheExpectedSalt() throws {
        let identityA = try HandshakeVector.identity(HandshakeVector.staticPrivateKeyA)
        let identityB = try HandshakeVector.identity(HandshakeVector.staticPrivateKeyB)
        XCTAssertEqual(
            HandshakeRole.role(localDeviceID: identityB.deviceID, peerDeviceID: identityA.deviceID),
            .initiator
        )
        XCTAssertEqual(
            HexEncoding.encode(Handshake.salt(localDeviceID: identityA.deviceID, peerDeviceID: identityB.deviceID)),
            HandshakeVector.salt
        )
    }

    func testFixedKeysProduceTheExpectedSessionKeysAndTags() throws {
        let initiator = try derive(role: .initiator)
        let responder = try derive(role: .responder)
        XCTAssertEqual(HexEncoding.encode(initiator.sendKey), HandshakeVector.initiatorToResponderKey)
        XCTAssertEqual(HexEncoding.encode(initiator.receiveKey), HandshakeVector.responderToInitiatorKey)
        XCTAssertEqual(HexEncoding.encode(responder.sendKey), HandshakeVector.responderToInitiatorKey)
        XCTAssertEqual(HexEncoding.encode(responder.receiveKey), HandshakeVector.initiatorToResponderKey)
        XCTAssertEqual(HexEncoding.encode(initiator.confirmationTag), HandshakeVector.initiatorTag)
        XCTAssertEqual(HexEncoding.encode(responder.confirmationTag), HandshakeVector.responderTag)
        XCTAssertTrue(initiator.verifyPeerConfirmationTag(responder.confirmationTag))
        XCTAssertTrue(responder.verifyPeerConfirmationTag(initiator.confirmationTag))
    }

    private func derive(role: HandshakeRole) throws -> HandshakeResult {
        let isInitiator = role == .initiator
        let identity = try HandshakeVector.identity(
            isInitiator ? HandshakeVector.staticPrivateKeyB : HandshakeVector.staticPrivateKeyA
        )
        let ephemeral = try HandshakeVector.ephemeral(
            isInitiator ? HandshakeVector.ephemeralPrivateKeyB : HandshakeVector.ephemeralPrivateKeyA
        )
        let peerIdentity = try HandshakeVector.identity(
            isInitiator ? HandshakeVector.staticPrivateKeyA : HandshakeVector.staticPrivateKeyB
        )
        let peerEphemeral = try HandshakeVector.ephemeral(
            isInitiator ? HandshakeVector.ephemeralPrivateKeyA : HandshakeVector.ephemeralPrivateKeyB
        )
        return try Handshake.derive(
            role: role,
            identity: identity,
            ephemeral: ephemeral,
            peerDeviceID: peerIdentity.deviceID,
            peerStaticPublicKey: peerIdentity.publicKey,
            peerEphemeralPublicKey: peerEphemeral.publicKey
        )
    }
}
