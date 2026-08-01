import Foundation

public struct ShizukuStartResultMessage: Codable, Hashable, Sendable {
    public let started: Bool
    public let reason: String?

    public init(started: Bool, reason: String? = nil) {
        self.started = started
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case started
        case reason
    }
}
