import Foundation

public struct PingMessage: Codable, Hashable, Sendable {
    public let seq: Int

    public init(seq: Int) {
        self.seq = seq
    }

    enum CodingKeys: String, CodingKey {
        case seq
    }
}
