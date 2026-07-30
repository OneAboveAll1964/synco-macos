import Foundation

public struct PairResponseMessage: Codable, Hashable, Sendable {
    public let accepted: Bool
    public let deviceID: DeviceID
    public let staticPublicKey: Data

    public init(accepted: Bool, deviceID: DeviceID, staticPublicKey: Data) {
        self.accepted = accepted
        self.deviceID = deviceID
        self.staticPublicKey = staticPublicKey
    }

    enum CodingKeys: String, CodingKey {
        case accepted
        case deviceID = "did"
        case staticPublicKey = "sPub"
    }
}
