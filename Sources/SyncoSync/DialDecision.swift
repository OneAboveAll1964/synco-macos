import Foundation
import SyncoCore

public enum DialDecision: String, Hashable, Sendable, CaseIterable {
    case dial
    case wait

    public static func decision(local: DeviceID, peer: DeviceID) -> DialDecision {
        local.isInitiator(against: peer) ? .dial : .wait
    }

    public var expectedOrigin: SessionOrigin {
        self == .dial ? .dialed : .accepted
    }
}
