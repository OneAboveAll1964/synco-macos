import SyncoCore
import XCTest
@testable import SyncoCrypto

final class SharedHandshakeVectorTests: XCTestCase {

    func testSharedVectorsProduceTheExpectedPublicKeysAndDeviceIDs() throws {
        try forEachVector { vector, parties in
            XCTAssertEqual(HexEncoding.encode(parties.identityA.publicKey), vector.staticPublicA, vector.name)
            XCTAssertEqual(HexEncoding.encode(parties.identityB.publicKey), vector.staticPublicB, vector.name)
            XCTAssertEqual(HexEncoding.encode(parties.ephemeralA.publicKey), vector.ephemeralPublicA, vector.name)
            XCTAssertEqual(HexEncoding.encode(parties.ephemeralB.publicKey), vector.ephemeralPublicB, vector.name)
            XCTAssertEqual(parties.identityA.deviceID.rawValue, vector.deviceIDA, vector.name)
            XCTAssertEqual(parties.identityB.deviceID.rawValue, vector.deviceIDB, vector.name)
        }
    }

    func testSharedVectorsAgreeOnWhichSideInitiates() throws {
        try forEachVector { vector, parties in
            XCTAssertEqual(
                HandshakeRole.role(
                    localDeviceID: parties.identityB.deviceID,
                    peerDeviceID: parties.identityA.deviceID
                ),
                .initiator,
                vector.name
            )
            XCTAssertEqual(
                HandshakeRole.role(
                    localDeviceID: parties.identityA.deviceID,
                    peerDeviceID: parties.identityB.deviceID
                ),
                .responder,
                vector.name
            )
        }
    }

    func testSharedVectorsProduceTheExpectedDirectionalSessionKeys() throws {
        try forEachVector { vector, parties in
            let initiator = try parties.initiator()
            let responder = try parties.responder()
            XCTAssertEqual(HexEncoding.encode(initiator.sendKey), vector.initiatorToResponderKey, vector.name)
            XCTAssertEqual(HexEncoding.encode(initiator.receiveKey), vector.responderToInitiatorKey, vector.name)
            XCTAssertEqual(HexEncoding.encode(responder.sendKey), vector.responderToInitiatorKey, vector.name)
            XCTAssertEqual(HexEncoding.encode(responder.receiveKey), vector.initiatorToResponderKey, vector.name)
        }
    }

    func testSharedVectorsProduceTheExpectedConfirmationTags() throws {
        try forEachVector { vector, parties in
            let initiator = try parties.initiator()
            let responder = try parties.responder()
            XCTAssertEqual(HexEncoding.encode(initiator.confirmationTag), vector.initiatorTag, vector.name)
            XCTAssertEqual(HexEncoding.encode(responder.confirmationTag), vector.responderTag, vector.name)
            XCTAssertTrue(responder.verifyPeerConfirmationTag(initiator.confirmationTag), vector.name)
            XCTAssertTrue(initiator.verifyPeerConfirmationTag(responder.confirmationTag), vector.name)
        }
    }

    private func forEachVector(_ assertion: (SharedHandshakeVector, Parties) throws -> Void) throws {
        for vector in SharedHandshakeVectors.all {
            try assertion(vector, try Parties(vector))
        }
    }

    private struct Parties {
        let identityA: DeviceIdentity
        let identityB: DeviceIdentity
        let ephemeralA: EphemeralKeyPair
        let ephemeralB: EphemeralKeyPair

        init(_ vector: SharedHandshakeVector) throws {
            identityA = try DeviceIdentity(
                privateKeyRepresentation: try HexEncoding.decode(vector.staticPrivateA)
            )
            identityB = try DeviceIdentity(
                privateKeyRepresentation: try HexEncoding.decode(vector.staticPrivateB)
            )
            ephemeralA = try EphemeralKeyPair.restored(
                privateKeyRepresentation: try HexEncoding.decode(vector.ephemeralPrivateA)
            )
            ephemeralB = try EphemeralKeyPair.restored(
                privateKeyRepresentation: try HexEncoding.decode(vector.ephemeralPrivateB)
            )
        }

        func initiator() throws -> HandshakeResult {
            try Handshake.derive(
                role: .initiator,
                identity: identityB,
                ephemeral: ephemeralB,
                peerDeviceID: identityA.deviceID,
                peerStaticPublicKey: identityA.publicKey,
                peerEphemeralPublicKey: ephemeralA.publicKey
            )
        }

        func responder() throws -> HandshakeResult {
            try Handshake.derive(
                role: .responder,
                identity: identityA,
                ephemeral: ephemeralA,
                peerDeviceID: identityB.deviceID,
                peerStaticPublicKey: identityB.publicKey,
                peerEphemeralPublicKey: ephemeralB.publicKey
            )
        }
    }
}
