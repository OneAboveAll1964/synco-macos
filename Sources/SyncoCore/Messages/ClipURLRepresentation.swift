import Foundation

public struct ClipURLRepresentation: Codable, Hashable, Sendable {
    public let url: String
    public let title: String?

    public init(url: String, title: String? = nil) {
        self.url = url
        self.title = title
    }

    enum CodingKeys: String, CodingKey {
        case url
        case title
    }
}
