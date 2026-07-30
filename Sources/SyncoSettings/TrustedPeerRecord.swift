import Foundation
import SyncoCore
import SyncoCrypto

public struct TrustedPeerRecord: Codable, Hashable, Sendable, Identifiable {
    public let deviceID: DeviceID
    public var staticPublicKey: Data
    public var displayName: String
    public var platform: DevicePlatform
    public var firstPairedAt: Date
    public var rejected: Bool

    public var id: DeviceID { deviceID }

    public init(
        deviceID: DeviceID,
        staticPublicKey: Data,
        displayName: String,
        platform: DevicePlatform,
        firstPairedAt: Date = Date(),
        rejected: Bool = false
    ) {
        self.deviceID = deviceID
        self.staticPublicKey = staticPublicKey
        self.displayName = displayName
        self.platform = platform
        self.firstPairedAt = firstPairedAt
        self.rejected = rejected
    }

    public var fingerprint: Fingerprint? {
        try? DeviceIdentity.fingerprint(forStaticPublicKey: staticPublicKey)
    }

    public var keyMatchesDeviceID: Bool {
        DeviceIdentity.staticPublicKey(staticPublicKey, matches: deviceID)
    }

    public var isUsable: Bool { keyMatchesDeviceID && !rejected }

    enum CodingKeys: String, CodingKey {
        case deviceID = "did"
        case staticPublicKey = "sPub"
        case displayName = "dn"
        case platform = "pl"
        case firstPairedAt
        case rejected
    }
}
