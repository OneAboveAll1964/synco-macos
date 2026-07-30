import Foundation

public enum ControlMessage: Codable, Hashable, Sendable {
    case hello(HelloMessage)
    case auth(AuthMessage)
    case pairRequest(PairRequestMessage)
    case pairResponse(PairResponseMessage)
    case caps(CapsMessage)
    case ping(PingMessage)
    case pong(PongMessage)
    case clip(ClipMessage)
    case transferStart(TransferStartMessage)
    case transferEnd(TransferEndMessage)
    case transferAbort(TransferAbortMessage)
    case ack(AckMessage)
    case bye(ByeMessage)
    case unknown(type: String)

    enum DiscriminatorKey: String, CodingKey {
        case t
    }

    public var type: ControlMessageType? {
        ControlMessageType(rawValue: typeIdentifier)
    }

    public var typeIdentifier: String {
        switch self {
        case .hello: return ControlMessageType.hello.rawValue
        case .auth: return ControlMessageType.auth.rawValue
        case .pairRequest: return ControlMessageType.pairRequest.rawValue
        case .pairResponse: return ControlMessageType.pairResponse.rawValue
        case .caps: return ControlMessageType.caps.rawValue
        case .ping: return ControlMessageType.ping.rawValue
        case .pong: return ControlMessageType.pong.rawValue
        case .clip: return ControlMessageType.clip.rawValue
        case .transferStart: return ControlMessageType.transferStart.rawValue
        case .transferEnd: return ControlMessageType.transferEnd.rawValue
        case .transferAbort: return ControlMessageType.transferAbort.rawValue
        case .ack: return ControlMessageType.ack.rawValue
        case .bye: return ControlMessageType.bye.rawValue
        case .unknown(let identifier): return identifier
        }
    }

    private var encodableBody: (any Encodable)? {
        switch self {
        case .hello(let body): return body
        case .auth(let body): return body
        case .pairRequest(let body): return body
        case .pairResponse(let body): return body
        case .caps(let body): return body
        case .ping(let body): return body
        case .pong(let body): return body
        case .clip(let body): return body
        case .transferStart(let body): return body
        case .transferEnd(let body): return body
        case .transferAbort(let body): return body
        case .ack(let body): return body
        case .bye(let body): return body
        case .unknown: return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let discriminator = try decoder.container(keyedBy: DiscriminatorKey.self)
        let identifier = try discriminator.decode(String.self, forKey: .t)
        switch ControlMessageType(rawValue: identifier) {
        case .hello: self = .hello(try HelloMessage(from: decoder))
        case .auth: self = .auth(try AuthMessage(from: decoder))
        case .pairRequest: self = .pairRequest(try PairRequestMessage(from: decoder))
        case .pairResponse: self = .pairResponse(try PairResponseMessage(from: decoder))
        case .caps: self = .caps(try CapsMessage(from: decoder))
        case .ping: self = .ping(try PingMessage(from: decoder))
        case .pong: self = .pong(try PongMessage(from: decoder))
        case .clip: self = .clip(try ClipMessage(from: decoder))
        case .transferStart: self = .transferStart(try TransferStartMessage(from: decoder))
        case .transferEnd: self = .transferEnd(try TransferEndMessage(from: decoder))
        case .transferAbort: self = .transferAbort(try TransferAbortMessage(from: decoder))
        case .ack: self = .ack(try AckMessage(from: decoder))
        case .bye: self = .bye(try ByeMessage(from: decoder))
        case .none: self = .unknown(type: identifier)
        }
    }

    public func encode(to encoder: Encoder) throws {
        try encodableBody?.encode(to: encoder)
        var discriminator = encoder.container(keyedBy: DiscriminatorKey.self)
        try discriminator.encode(typeIdentifier, forKey: .t)
    }
}
