import Foundation
import SyncoCore
import SyncoCrypto

public struct TrustedPeerRecord: Hashable, Sendable {
    public let deviceID: DeviceID
    public let staticPublicKey: Data
    public let displayName: String
    public let platform: DevicePlatform

    public init(
        deviceID: DeviceID,
        staticPublicKey: Data,
        displayName: String,
        platform: DevicePlatform
    ) {
        self.deviceID = deviceID
        self.staticPublicKey = staticPublicKey
        self.displayName = displayName
        self.platform = platform
    }

    public var keyMatchesDeviceID: Bool {
        DeviceIdentity.staticPublicKey(staticPublicKey, matches: deviceID)
    }

    public var descriptor: PeerDescriptor {
        PeerDescriptor(deviceID: deviceID, displayName: displayName, platform: platform)
    }
}
