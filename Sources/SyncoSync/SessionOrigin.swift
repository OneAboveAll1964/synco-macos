import Foundation
import SyncoCore

public enum SessionOrigin: String, Hashable, Sendable, CaseIterable {
    case dialed
    case accepted

    public static func expected(local: DeviceID, peer: DeviceID) -> SessionOrigin {
        DialDecision.decision(local: local, peer: peer).expectedOrigin
    }
}
