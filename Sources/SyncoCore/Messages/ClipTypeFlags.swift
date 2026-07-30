import Foundation

public struct ClipTypeFlags: Codable, Hashable, Sendable {
    public var text: Bool
    public var image: Bool
    public var file: Bool

    public init(text: Bool, image: Bool, file: Bool) {
        self.text = text
        self.image = image
        self.file = file
    }

    public static let all = ClipTypeFlags(text: true, image: true, file: true)
    public static let none = ClipTypeFlags(text: false, image: false, file: false)

    public func allows(_ kind: ClipRepresentationKind) -> Bool {
        switch kind {
        case .text, .html, .rtf, .url: return text
        case .image: return image
        case .file: return file
        }
    }

    public var allowsNothing: Bool { !text && !image && !file }

    enum CodingKeys: String, CodingKey {
        case text
        case image
        case file
    }
}
