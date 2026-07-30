import Foundation
import SyncoCore
import SyncoDiscovery

public struct PeerReconciliation: Hashable, Sendable {
    public let localDeviceID: DeviceID

    public init(localDeviceID: DeviceID) {
        self.localDeviceID = localDeviceID
    }

    public func plan(
        discovered: DiscoveredPeer?,
        isTrusted: Bool,
        hasLiveSession: Bool
    ) -> PeerLinkPlan {
        guard isTrusted else { return .unpaired }
        guard !hasLiveSession else { return .standby }
        guard let discovered, discovered.deviceID != localDeviceID else { return .standby }
        switch DialDecision.decision(local: localDeviceID, peer: discovered.deviceID) {
        case .dial: return .dial(discovered.endpoint)
        case .wait: return .awaitPeer
        }
    }

    public func decision(for peerDeviceID: DeviceID) -> DialDecision {
        DialDecision.decision(local: localDeviceID, peer: peerDeviceID)
    }

    public func expectedOrigin(for peerDeviceID: DeviceID) -> SessionOrigin {
        SessionOrigin.expected(local: localDeviceID, peer: peerDeviceID)
    }
}
