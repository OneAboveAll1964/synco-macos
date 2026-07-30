import Foundation
import SyncoCore

public struct ServiceAdvertisement: Hashable, Sendable {
    public let deviceID: DeviceID
    public let displayName: String
    public let platform: DevicePlatform
    public let fingerprint: Fingerprint
    public let version: Int

    public init(
        deviceID: DeviceID,
        displayName: String,
        platform: DevicePlatform = .current,
        fingerprint: Fingerprint,
        version: Int = SyncoConstants.protocolVersion
    ) {
        self.deviceID = deviceID
        self.displayName = displayName
        self.platform = platform
        self.fingerprint = fingerprint
        self.version = version
    }

    public var serviceInstanceName: String {
        deviceID.rawValue
    }

    public func renamed(_ displayName: String) -> ServiceAdvertisement {
        ServiceAdvertisement(
            deviceID: deviceID,
            displayName: displayName,
            platform: platform,
            fingerprint: fingerprint,
            version: version
        )
    }
}
