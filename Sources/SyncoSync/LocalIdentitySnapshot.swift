import Foundation
import SyncoCore
import SyncoCrypto

public struct LocalIdentitySnapshot: Hashable, Sendable {
    public let deviceID: DeviceID
    public let fingerprint: Fingerprint
    public let displayName: String
    public let platform: DevicePlatform

    public init(
        deviceID: DeviceID,
        fingerprint: Fingerprint,
        displayName: String,
        platform: DevicePlatform = .current
    ) {
        self.deviceID = deviceID
        self.fingerprint = fingerprint
        self.displayName = displayName
        self.platform = platform
    }

    public init(identity: DeviceIdentity, displayName: String) {
        self.init(
            deviceID: identity.deviceID,
            fingerprint: identity.fingerprint,
            displayName: displayName
        )
    }
}
