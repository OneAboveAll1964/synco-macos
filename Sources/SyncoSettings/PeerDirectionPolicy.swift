import Foundation
import SyncoCore

public struct PeerDirectionPolicy: Codable, Hashable, Sendable {
    public var send: ClipTypeFlags
    public var receive: ClipTypeFlags
    public var revision: Int64

    public static let bidirectional = PeerDirectionPolicy(send: .all, receive: .all)
    public static let receiveOnly = PeerDirectionPolicy(send: .none, receive: .all)
    public static let sendOnly = PeerDirectionPolicy(send: .all, receive: .none)
    public static let disabled = PeerDirectionPolicy(send: .none, receive: .none)

    public init(send: ClipTypeFlags, receive: ClipTypeFlags, revision: Int64 = 0) {
        self.send = send
        self.receive = receive
        self.revision = revision
    }

    public var mirrored: PeerDirectionPolicy {
        PeerDirectionPolicy(send: receive, receive: send, revision: revision)
    }

    public func supersedes(
        _ other: PeerDirectionPolicy,
        ours: DeviceID,
        theirs: DeviceID
    ) -> Bool {
        if revision != other.revision { return revision > other.revision }
        return theirs.rawValue < ours.rawValue
    }

    public var allowsNothing: Bool {
        send.allowsNothing && receive.allowsNothing
    }

    enum CodingKeys: String, CodingKey {
        case send
        case receive
        case revision
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        send = try container.decode(ClipTypeFlags.self, forKey: .send)
        receive = try container.decode(ClipTypeFlags.self, forKey: .receive)
        revision = try container.decodeIfPresent(Int64.self, forKey: .revision) ?? 0
    }
}
