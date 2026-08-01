import Foundation

public enum ControlMessageType: String, Hashable, Sendable, CaseIterable {
    case hello
    case auth
    case pairRequest
    case pairResponse
    case caps
    case policy
    case ping
    case pong
    case clip
    case transferStart
    case transferEnd
    case transferAbort
    case transferProgress
    case ack
    case bye

    public var isPlaintextHandshake: Bool {
        switch self {
        case .hello, .auth, .pairRequest, .pairResponse: return true
        default: return false
        }
    }
}
