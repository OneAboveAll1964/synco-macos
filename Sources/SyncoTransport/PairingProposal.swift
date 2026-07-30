import Foundation
import SyncoCore
import SyncoCrypto

public struct PairingProposal: Hashable, Sendable {
    public let deviceID: DeviceID
    public let displayName: String
    public let platform: DevicePlatform
    public let staticPublicKey: Data
    public let fingerprint: Fingerprint

    init(request: PairRequestMessage) throws {
        guard DeviceIdentity.staticPublicKey(request.staticPublicKey, matches: request.deviceID) else {
            throw SyncoError.didMismatch
        }
        let derived = try DeviceIdentity.fingerprint(forStaticPublicKey: request.staticPublicKey)
        guard derived == request.fingerprint else {
            throw SyncoError.didMismatch
        }
        deviceID = request.deviceID
        displayName = request.displayName
        platform = request.platform
        staticPublicKey = request.staticPublicKey
        fingerprint = derived
    }

    public var trustedPeerRecord: TrustedPeerRecord {
        TrustedPeerRecord(
            deviceID: deviceID,
            staticPublicKey: staticPublicKey,
            displayName: displayName,
            platform: platform
        )
    }
}
