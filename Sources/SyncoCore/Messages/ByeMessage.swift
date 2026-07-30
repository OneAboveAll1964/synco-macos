import Foundation

public struct ByeMessage: Codable, Hashable, Sendable {
    public let reason: CloseReason

    public init(reason: CloseReason) {
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case reason
    }
}
