import Foundation

public struct RemoteRejectMessage: Codable, Hashable, Sendable {
    public enum Reason: String, Codable, Sendable {
        case screenPermission
        case inputPermission
        case busy
        case unsupported
    }

    public let reason: Reason

    public init(reason: Reason) {
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case reason
    }
}
