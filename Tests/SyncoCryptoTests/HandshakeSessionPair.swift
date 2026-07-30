import Foundation
import SyncoCore
@testable import SyncoCrypto

struct HandshakeSessionPair {
    let initiator: DeviceIdentity
    let responder: DeviceIdentity
    let initiatorEphemeral: EphemeralKeyPair
    let responderEphemeral: EphemeralKeyPair
    let initiatorResult: HandshakeResult
    let responderResult: HandshakeResult

    init() throws {
        var first = try DeviceIdentity.generate()
        var second = try DeviceIdentity.generate()
        while first.deviceID == second.deviceID {
            second = try DeviceIdentity.generate()
        }
        if second.deviceID < first.deviceID {
            swap(&first, &second)
        }
        initiator = first
        responder = second
        initiatorEphemeral = EphemeralKeyPair.generate()
        responderEphemeral = EphemeralKeyPair.generate()
        initiatorResult = try Handshake.derive(
            role: .initiator,
            identity: initiator,
            ephemeral: initiatorEphemeral,
            peerDeviceID: responder.deviceID,
            peerStaticPublicKey: responder.publicKey,
            peerEphemeralPublicKey: responderEphemeral.publicKey
        )
        responderResult = try Handshake.derive(
            role: .responder,
            identity: responder,
            ephemeral: responderEphemeral,
            peerDeviceID: initiator.deviceID,
            peerStaticPublicKey: initiator.publicKey,
            peerEphemeralPublicKey: initiatorEphemeral.publicKey
        )
    }
}
