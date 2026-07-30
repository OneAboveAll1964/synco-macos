import Foundation
import SyncoCore

public enum TransportError: Error, Hashable, Sendable {
    case connectionFailed(String)
    case connectionClosed
    case listenerUnavailable(String)
    case listenerFailed(String)
    case listenerWithoutPort
    case timedOut
    case unexpectedHandshakeMessage(String)
    case peerClosed(CloseReason)

    public var closeReason: CloseReason {
        switch self {
        case .timedOut:
            return .timeout
        case .unexpectedHandshakeMessage:
            return .badHandshake
        case .peerClosed(let reason):
            return reason
        case .connectionFailed, .connectionClosed, .listenerUnavailable, .listenerFailed,
             .listenerWithoutPort:
            return .shutdown
        }
    }
}
