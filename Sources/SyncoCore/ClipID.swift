import Foundation

public struct ClipID: UUIDBackedIdentifier {
    public let uuid: UUID

    public init(uuid: UUID) {
        self.uuid = uuid
    }

    public init() {
        self.init(uuid: UUID())
    }

    public init(from decoder: Decoder) throws {
        self = try Self.decodeIdentifier(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try encodeIdentifier(to: encoder)
    }
}
