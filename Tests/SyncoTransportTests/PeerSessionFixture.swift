import Foundation
import SyncoCore
import SyncoCrypto
@testable import SyncoTransport

enum PeerSessionFixture {
    static func distinctIdentities() throws -> (DeviceIdentity, DeviceIdentity) {
        let first = try DeviceIdentity.generate()
        var second = try DeviceIdentity.generate()
        while second.deviceID == first.deviceID {
            second = try DeviceIdentity.generate()
        }
        return (first, second)
    }

    static func configuration(
        identity: DeviceIdentity,
        trusting identities: [DeviceIdentity],
        approving decision: PairingDecision = .reject
    ) -> PeerSessionConfiguration {
        PeerSessionConfiguration(
            identity: identity,
            displayName: "Test \(identity.deviceID.rawValue.prefix(4))",
            trustedPeers: TrustedPeerTable(identities),
            pairingApproval: FixedPairingApproval(decision: decision),
            handshakeTimeout: .seconds(5),
            pairingTimeout: .seconds(5),
            pingInterval: .seconds(15),
            readTimeout: .seconds(45)
        )
    }

    static func textClip(origin: DeviceID, text: String) -> ClipMessage {
        let representations: [ClipRepresentation] = [.text(text)]
        return ClipMessage(
            id: ClipID(),
            timestampMilliseconds: 1_730_300_000_000,
            origin: origin,
            hash: ClipCanonicalHash.hexDigest(for: representations),
            representations: representations
        )
    }
}
