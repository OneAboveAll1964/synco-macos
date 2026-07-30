import Foundation
import SyncoSync

public enum DirectionChoice: String, Hashable, Sendable, CaseIterable, Identifiable {
    case bothWays
    case macToPeer
    case peerToMac
    case paused

    public var id: String { rawValue }

    public init(direction: SyncDirection, paused: Bool) {
        guard !paused else {
            self = .paused
            return
        }
        switch direction {
        case .bidirectional: self = .bothWays
        case .sendOnly: self = .macToPeer
        case .receiveOnly: self = .peerToMac
        case .disabled: self = .paused
        }
    }

    public var direction: SyncDirection? {
        switch self {
        case .bothWays: return .bidirectional
        case .macToPeer: return .sendOnly
        case .peerToMac: return .receiveOnly
        case .paused: return nil
        }
    }

    public var isPaused: Bool { self == .paused }

    var title: String {
        switch self {
        case .bothWays: return "Both ways"
        case .macToPeer: return "Mac to phone"
        case .peerToMac: return "Phone to Mac"
        case .paused: return "Paused"
        }
    }

    var symbolName: String {
        switch self {
        case .bothWays: return "arrow.left.arrow.right"
        case .macToPeer: return "arrow.right"
        case .peerToMac: return "arrow.left"
        case .paused: return "pause.fill"
        }
    }

    var detail: String {
        switch self {
        case .bothWays: return "Copies on either device appear on the other."
        case .macToPeer: return "This Mac sends copies. Nothing lands on this Mac."
        case .peerToMac: return "Copies from your phone land here. This Mac sends nothing."
        case .paused: return "Nothing flows in either direction. Per-type choices are kept."
        }
    }
}
