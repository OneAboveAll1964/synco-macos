import Foundation
import SyncoCore
import SyncoSettings

public enum OutboundClipPolicy {
    public static func decide(
        representations: [ClipRepresentation],
        policy: SyncPolicy,
        peerMaxBlobBytes: Int64? = nil
    ) -> OutboundClipDecision {
        let permitted = clamped(policy, peerMaxBlobBytes: peerMaxBlobBytes).sendable(representations)
        return permitted.isEmpty ? .drop : .send(permitted)
    }

    public static func clamped(_ policy: SyncPolicy, peerMaxBlobBytes: Int64?) -> SyncPolicy {
        guard let peerMaxBlobBytes, peerMaxBlobBytes < policy.maxBlobBytes else { return policy }
        var clamped = policy
        clamped.maxBlobBytes = max(0, peerMaxBlobBytes)
        return clamped
    }
}
