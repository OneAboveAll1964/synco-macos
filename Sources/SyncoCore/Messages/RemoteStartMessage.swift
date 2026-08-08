import Foundation

public struct RemoteStartMessage: Codable, Hashable, Sendable {
    public let maxWidth: Int
    public let maxHeight: Int
    public let fps: Int
    public let input: Bool

    public init(maxWidth: Int, maxHeight: Int, fps: Int, input: Bool) {
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.fps = fps
        self.input = input
    }

    enum CodingKeys: String, CodingKey {
        case maxWidth
        case maxHeight
        case fps
        case input
    }
}
