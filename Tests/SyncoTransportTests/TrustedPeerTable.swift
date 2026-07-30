import Foundation
import SyncoCore
import SyncoCrypto
@testable import SyncoTransport

struct TrustedPeerTable: TrustedPeerProviding {
    private let records: [DeviceID: TrustedPeerRecord]

    init(_ identities: [DeviceIdentity]) {
        records = Dictionary(
            uniqueKeysWithValues: identities.map { identity in
                (
                    identity.deviceID,
                    TrustedPeerRecord(
                        deviceID: identity.deviceID,
                        staticPublicKey: identity.publicKey,
                        displayName: identity.deviceID.rawValue,
                        platform: .macOS
                    )
                )
            }
        )
    }

    func trustedPeer(for deviceID: DeviceID) async -> TrustedPeerRecord? {
        records[deviceID]
    }
}
