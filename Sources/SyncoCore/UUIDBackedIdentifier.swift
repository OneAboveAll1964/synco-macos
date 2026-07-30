import Foundation

public protocol UUIDBackedIdentifier: Hashable, Sendable, Codable, CustomStringConvertible {
    var uuid: UUID { get }
    init(uuid: UUID)
}

extension UUIDBackedIdentifier {
    public var stringValue: String { uuid.uuidString.lowercased() }

    public var description: String { stringValue }

    public var rawBytes: Data {
        withUnsafeBytes(of: uuid.uuid) { Data($0) }
    }

    public init?(parsing text: String) {
        guard let uuid = UUID(uuidString: text) else { return nil }
        self.init(uuid: uuid)
    }

    public init?(rawBytes: Data) {
        guard rawBytes.count == SyncoConstants.Framing.transferIDBytes else { return nil }
        let b = Array(rawBytes)
        self.init(uuid: UUID(uuid: (
            b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
            b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]
        )))
    }

    public static func decodeIdentifier(from decoder: Decoder) throws -> Self {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let identifier = Self(parsing: text) else {
            throw SyncoError.malformedMessage(text)
        }
        return identifier
    }

    public func encodeIdentifier(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
