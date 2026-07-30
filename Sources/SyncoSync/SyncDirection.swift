import Foundation
import SyncoSettings

public enum SyncDirection: String, Hashable, Sendable, CaseIterable, Identifiable {
    case bidirectional
    case receiveOnly
    case sendOnly
    case disabled

    public var id: String { rawValue }

    public var policy: PeerDirectionPolicy {
        switch self {
        case .bidirectional: return .bidirectional
        case .receiveOnly: return .receiveOnly
        case .sendOnly: return .sendOnly
        case .disabled: return .disabled
        }
    }

    public var title: String {
        switch self {
        case .bidirectional: return "Both ways"
        case .receiveOnly: return "Receive only"
        case .sendOnly: return "Send only"
        case .disabled: return "Off"
        }
    }

    public init(policy: PeerDirectionPolicy) {
        let sends = !policy.send.allowsNothing
        let receives = !policy.receive.allowsNothing
        switch (sends, receives) {
        case (true, true): self = .bidirectional
        case (false, true): self = .receiveOnly
        case (true, false): self = .sendOnly
        case (false, false): self = .disabled
        }
    }
}
