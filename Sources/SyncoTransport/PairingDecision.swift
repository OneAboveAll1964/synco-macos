import Foundation

public enum PairingDecision: String, Hashable, Sendable, CaseIterable {
    case approve
    case reject

    public var accepted: Bool {
        self == .approve
    }
}
