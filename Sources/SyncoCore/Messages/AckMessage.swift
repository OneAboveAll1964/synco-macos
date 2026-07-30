import Foundation

public struct AckMessage: Codable, Hashable, Sendable {
    public let id: ClipID
    public let applied: Bool
    public let reason: ClipRejectionReason?

    public init(id: ClipID, applied: Bool, reason: ClipRejectionReason? = nil) {
        self.id = id
        self.applied = applied
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case id
        case applied
        case reason
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ClipID.self, forKey: .id)
        applied = try container.decode(Bool.self, forKey: .applied)
        reason = try container.decodeIfPresent(ClipRejectionReason.self, forKey: .reason)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(applied, forKey: .applied)
        try container.encode(reason, forKey: .reason)
    }
}
