import Foundation
import Network
import SyncoCore

public struct DiscoveredPeer: Hashable, Sendable, Identifiable {
    public let deviceID: DeviceID
    public let displayName: String
    public let platform: DevicePlatform
    public let fingerprint: Fingerprint
    public let endpoint: NWEndpoint
    public let lastSeen: Date

    public init(
        advertisement: ServiceAdvertisement,
        endpoint: NWEndpoint,
        lastSeen: Date = Date()
    ) {
        deviceID = advertisement.deviceID
        displayName = advertisement.displayName
        platform = advertisement.platform
        fingerprint = advertisement.fingerprint
        self.endpoint = endpoint
        self.lastSeen = lastSeen
    }

    public var id: DeviceID { deviceID }

    public var advertisement: ServiceAdvertisement {
        ServiceAdvertisement(
            deviceID: deviceID,
            displayName: displayName,
            platform: platform,
            fingerprint: fingerprint
        )
    }

    public func announcesSameState(as other: DiscoveredPeer) -> Bool {
        deviceID == other.deviceID
            && displayName == other.displayName
            && platform == other.platform
            && fingerprint == other.fingerprint
            && endpoint == other.endpoint
    }
}
