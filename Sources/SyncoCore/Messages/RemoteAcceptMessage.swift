import Foundation

public struct RemoteAcceptMessage: Codable, Hashable, Sendable {
    public let codec: String
    public let width: Int
    public let height: Int
    public let fps: Int
    public let input: Bool

    public init(codec: String = "h264", width: Int, height: Int, fps: Int, input: Bool) {
        self.codec = codec
        self.width = width
        self.height = height
        self.fps = fps
        self.input = input
    }

    enum CodingKeys: String, CodingKey {
        case codec
        case width
        case height
        case fps
        case input
    }
}
