import Foundation

public struct PolicyMessage: Codable, Hashable, Sendable {
    public let rev: Int64
    public let send: ClipTypeFlags
    public let recv: ClipTypeFlags
    public let paused: Bool
    public let maxBlob: Int64

    public init(
        rev: Int64,
        send: ClipTypeFlags,
        recv: ClipTypeFlags,
        paused: Bool = false,
        maxBlob: Int64 = SyncoConstants.Limits.defaultMaxBlobBytes
    ) {
        self.rev = rev
        self.send = send
        self.recv = recv
        self.paused = paused
        self.maxBlob = maxBlob
    }

    public var mirrored: PolicyMessage {
        PolicyMessage(rev: rev, send: recv, recv: send, paused: paused, maxBlob: maxBlob)
    }

    enum CodingKeys: String, CodingKey {
        case rev
        case send
        case recv
        case paused
        case maxBlob
    }
}
