import Foundation

public struct CloseReason: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let versionMismatch = CloseReason(rawValue: "versionMismatch")
    public static let selfConnection = CloseReason(rawValue: "selfConnection")
    public static let unknownKey = CloseReason(rawValue: "unknownKey")
    public static let didMismatch = CloseReason(rawValue: "didMismatch")
    public static let badHandshake = CloseReason(rawValue: "badHandshake")
    public static let badAuth = CloseReason(rawValue: "badAuth")
    public static let frameTooLarge = CloseReason(rawValue: "frameTooLarge")
    public static let replay = CloseReason(rawValue: "replay")
    public static let timeout = CloseReason(rawValue: "timeout")
    public static let duplicateSession = CloseReason(rawValue: "duplicateSession")
    public static let shutdown = CloseReason(rawValue: "shutdown")
    public static let unpaired = CloseReason(rawValue: "unpaired")

    public static let allKnown: [CloseReason] = [
        .versionMismatch, .selfConnection, .unknownKey, .didMismatch,
        .badHandshake, .badAuth, .frameTooLarge, .replay,
        .timeout, .duplicateSession, .shutdown, .unpaired,
    ]

    public var description: String { rawValue }

    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
