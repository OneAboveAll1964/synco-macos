import Foundation

public struct AuthMessage: Codable, Hashable, Sendable {
    public let tag: Data

    public init(tag: Data) {
        self.tag = tag
    }

    enum CodingKeys: String, CodingKey {
        case tag
    }
}
