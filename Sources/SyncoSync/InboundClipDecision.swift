import Foundation
import SyncoCore
import SyncoSettings

public enum InboundClipDecision: Hashable, Sendable {
    case accept([ClipRepresentation])
    case reject(ClipRejectionReason)
    case ignore

    public static func decide(
        clip: ClipMessage,
        policy: SyncPolicy,
        localDeviceID: DeviceID
    ) -> InboundClipDecision {
        guard clip.origin != localDeviceID else { return .ignore }
        guard !clip.representations.isEmpty else { return .ignore }
        let acceptable = policy.acceptable(clip.representations)
        guard !acceptable.isEmpty else {
            return .reject(policy.rejection(for: clip.representations) ?? .typeDisabled)
        }
        return .accept(acceptable)
    }

    public var representations: [ClipRepresentation] {
        guard case .accept(let representations) = self else { return [] }
        return representations
    }

    public var rejectionReason: ClipRejectionReason? {
        guard case .reject(let reason) = self else { return nil }
        return reason
    }
}
