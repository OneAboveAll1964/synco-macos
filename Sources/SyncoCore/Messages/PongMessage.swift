import Foundation

public struct PongMessage: Codable, Hashable, Sendable {
    public let seq: Int

    public init(seq: Int) {
        self.seq = seq
    }

    public init(replyingTo ping: PingMessage) {
        self.seq = ping.seq
    }

    enum CodingKeys: String, CodingKey {
        case seq
    }
}
