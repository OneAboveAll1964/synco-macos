import Foundation

public enum ClipRepresentation: Codable, Hashable, Sendable {
    case text(String)
    case html(String)
    case rtf(Data)
    case url(ClipURLRepresentation)
    case image(ClipImageRepresentation)
    case file(ClipFileRepresentation)

    public var kind: ClipRepresentationKind {
        switch self {
        case .text: return .text
        case .html: return .html
        case .rtf: return .rtf
        case .url: return .url
        case .image: return .image
        case .file: return .file
        }
    }

    public var transferID: TransferID? {
        switch self {
        case .image(let representation): return representation.transferID
        case .file(let representation): return representation.transferID
        default: return nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case k
        case text
        case html
        case b64
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(ClipRepresentationKind.self, forKey: .k) {
        case .text: self = .text(try container.decode(String.self, forKey: .text))
        case .html: self = .html(try container.decode(String.self, forKey: .html))
        case .rtf: self = .rtf(try container.decode(Data.self, forKey: .b64))
        case .url: self = .url(try ClipURLRepresentation(from: decoder))
        case .image: self = .image(try ClipImageRepresentation(from: decoder))
        case .file: self = .file(try ClipFileRepresentation(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .k)
        switch self {
        case .text(let value): try container.encode(value, forKey: .text)
        case .html(let value): try container.encode(value, forKey: .html)
        case .rtf(let value): try container.encode(value, forKey: .b64)
        case .url(let representation): try representation.encode(to: encoder)
        case .image(let representation): try representation.encode(to: encoder)
        case .file(let representation): try representation.encode(to: encoder)
        }
    }
}
