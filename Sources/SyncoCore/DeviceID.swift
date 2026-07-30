import Foundation

public struct DeviceID: Hashable, Sendable, Codable, Comparable, CustomStringConvertible {
    public let rawValue: String

    public init(validating rawValue: String) throws {
        guard rawValue.utf8.count == SyncoConstants.Identity.deviceIDCharacters,
              rawValue.utf8.allSatisfy(Base32.isLowercaseSymbol)
        else {
            throw SyncoError.invalidDeviceID(rawValue)
        }
        self.rawValue = rawValue
    }

    public init?(_ rawValue: String) {
        guard let identifier = try? DeviceID(validating: rawValue) else { return nil }
        self = identifier
    }

    public var description: String { rawValue }

    public func isInitiator(against peer: DeviceID) -> Bool {
        self < peer
    }

    public static func < (lhs: DeviceID, rhs: DeviceID) -> Bool {
        lhs.rawValue.utf8.lexicographicallyPrecedes(rhs.rawValue.utf8)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(validating: container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
