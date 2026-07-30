import Foundation
import SyncoCore

public enum PeerLinkStatus: Hashable, Sendable {
    case idle
    case waitingForPeer
    case connecting
    case online
    case retrying(Duration)
    case unpaired
    case closed(CloseReason)

    public var isOnline: Bool {
        self == .online
    }

    public var isEngaged: Bool {
        switch self {
        case .connecting, .online, .retrying, .waitingForPeer: return true
        case .idle, .unpaired, .closed: return false
        }
    }

    public var closeReason: CloseReason? {
        guard case .closed(let reason) = self else { return nil }
        return reason
    }
}
