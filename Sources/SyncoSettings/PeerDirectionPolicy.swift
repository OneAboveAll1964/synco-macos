import Foundation
import SyncoCore

public struct PeerDirectionPolicy: Codable, Hashable, Sendable {
    public var send: ClipTypeFlags
    public var receive: ClipTypeFlags

    public static let bidirectional = PeerDirectionPolicy(send: .all, receive: .all)
    public static let receiveOnly = PeerDirectionPolicy(send: .none, receive: .all)
    public static let sendOnly = PeerDirectionPolicy(send: .all, receive: .none)
    public static let disabled = PeerDirectionPolicy(send: .none, receive: .none)

    public init(send: ClipTypeFlags, receive: ClipTypeFlags) {
        self.send = send
        self.receive = receive
    }

    public var allowsNothing: Bool {
        send.allowsNothing && receive.allowsNothing
    }

    enum CodingKeys: String, CodingKey {
        case send
        case receive
    }
}
