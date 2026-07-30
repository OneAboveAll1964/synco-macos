import Foundation
import SyncoCore

public struct SyncEvent: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case clipSent
        case clipReceived
        case clipRejected(ClipRejectionReason)
        case clipDropped
        case clipFailed
        case paired
        case pairingRejected
        case unpaired
        case linkFailed(CloseReason)

        public var rejectionReason: ClipRejectionReason? {
            guard case .clipRejected(let reason) = self else { return nil }
            return reason
        }

        public var closeReason: CloseReason? {
            guard case .linkFailed(let reason) = self else { return nil }
            return reason
        }
    }

    public let id: UUID
    public let peerDeviceID: DeviceID
    public let kind: Kind
    public let clipID: ClipID?
    public let occurredAt: Date

    public init(
        id: UUID = UUID(),
        peerDeviceID: DeviceID,
        kind: Kind,
        clipID: ClipID? = nil,
        occurredAt: Date = Date()
    ) {
        self.id = id
        self.peerDeviceID = peerDeviceID
        self.kind = kind
        self.clipID = clipID
        self.occurredAt = occurredAt
    }
}
