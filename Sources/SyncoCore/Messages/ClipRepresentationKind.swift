import Foundation

public enum ClipRepresentationKind: String, Codable, Hashable, Sendable, CaseIterable {
    case text
    case html
    case rtf
    case url
    case image
    case file

    public var isInline: Bool {
        switch self {
        case .text, .html, .rtf, .url: return true
        case .image, .file: return false
        }
    }

    public var streamsAsBlob: Bool { !isInline }
}
