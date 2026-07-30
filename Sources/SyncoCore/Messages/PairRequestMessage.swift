import Foundation

public struct PairRequestMessage: Codable, Hashable, Sendable {
    public let deviceID: DeviceID
    public let displayName: String
    public let platform: DevicePlatform
    public let staticPublicKey: Data
    public let fingerprint: Fingerprint

    public init(
        deviceID: DeviceID,
        displayName: String,
        platform: DevicePlatform = .current,
        staticPublicKey: Data,
        fingerprint: Fingerprint
    ) {
        self.deviceID = deviceID
        self.displayName = displayName
        self.platform = platform
        self.staticPublicKey = staticPublicKey
        self.fingerprint = fingerprint
    }

    enum CodingKeys: String, CodingKey {
        case deviceID = "did"
        case displayName = "dn"
        case platform = "pl"
        case staticPublicKey = "sPub"
        case fingerprint = "fp"
    }
}
