import Foundation

public struct Fingerprint: Hashable, Sendable, Codable, CustomStringConvertible {
    public let compact: String

    public init(validatingCompact compact: String) throws {
        let uppercased = compact.uppercased()
        guard uppercased.utf8.count == SyncoConstants.Identity.fingerprintCharacters,
              uppercased.utf8.allSatisfy(HexEncoding.isHexadecimal)
        else {
            throw SyncoError.invalidFingerprint(compact)
        }
        self.compact = uppercased
    }

    public init(digestPrefix: Data) throws {
        guard digestPrefix.count == SyncoConstants.Identity.fingerprintDigestPrefixBytes else {
            throw SyncoError.invalidFingerprint(HexEncoding.encode(digestPrefix))
        }
        compact = HexEncoding.encode(digestPrefix, uppercase: true)
    }

    public init(parsing text: String) throws {
        let separator = SyncoConstants.Identity.fingerprintGroupSeparator
        try self.init(validatingCompact: text.replacingOccurrences(of: separator, with: ""))
    }

    public var grouped: String {
        let size = SyncoConstants.Identity.fingerprintGroupSize
        var groups: [String] = []
        var remainder = Substring(compact)
        while !remainder.isEmpty {
            groups.append(String(remainder.prefix(size)))
            remainder = remainder.dropFirst(size)
        }
        return groups.joined(separator: SyncoConstants.Identity.fingerprintGroupSeparator)
    }

    public var description: String { grouped }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(parsing: container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(grouped)
    }
}
