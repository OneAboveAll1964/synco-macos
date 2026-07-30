import Foundation

public struct HelloMessage: Codable, Hashable, Sendable {
    public let version: Int
    public let deviceID: DeviceID
    public let displayName: String
    public let platform: DevicePlatform
    public let ephemeralPublicKey: Data

    public init(
        version: Int = SyncoConstants.protocolVersion,
        deviceID: DeviceID,
        displayName: String,
        platform: DevicePlatform = .current,
        ephemeralPublicKey: Data
    ) {
        self.version = version
        self.deviceID = deviceID
        self.displayName = displayName
        self.platform = platform
        self.ephemeralPublicKey = ephemeralPublicKey
    }

    enum CodingKeys: String, CodingKey {
        case version = "v"
        case deviceID = "did"
        case displayName = "dn"
        case platform = "pl"
        case ephemeralPublicKey = "ePub"
    }
}
