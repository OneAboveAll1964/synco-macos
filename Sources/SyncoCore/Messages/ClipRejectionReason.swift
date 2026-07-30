import Foundation

public struct ClipRejectionReason: RawRepresentable, Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let typeDisabled = ClipRejectionReason(rawValue: "typeDisabled")
    public static let receiveDisabled = ClipRejectionReason(rawValue: "receiveDisabled")
    public static let tooLarge = ClipRejectionReason(rawValue: "tooLarge")
    public static let hashMismatch = ClipRejectionReason(rawValue: "hashMismatch")
    public static let userCancelled = ClipRejectionReason(rawValue: "userCancelled")

    public static let allKnown: [ClipRejectionReason] = [
        .typeDisabled, .receiveDisabled, .tooLarge, .hashMismatch, .userCancelled,
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
