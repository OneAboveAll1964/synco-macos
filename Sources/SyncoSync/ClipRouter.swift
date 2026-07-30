import Foundation
import SyncoCore
import SyncoSettings
import SyncoTransfer

public actor ClipRouter {
    public nonisolated let localDeviceID: DeviceID
    public nonisolated let peerDeviceID: DeviceID

    let transport: any ClipTransmitting
    let clipboard: any ClipboardApplying
    let transfers: TransferManager

    var policy: SyncPolicy
    var announcedCapabilities: CapsMessage?
    var pending: [ClipID: PendingInboundClip] = [:]
    var clipByTransfer: [TransferID: ClipID] = [:]
    var abortedOutgoing: Set<TransferID> = []

    public init(
        localDeviceID: DeviceID,
        peerDeviceID: DeviceID,
        transport: any ClipTransmitting,
        clipboard: any ClipboardApplying,
        transfers: TransferManager,
        policy: SyncPolicy
    ) {
        self.localDeviceID = localDeviceID
        self.peerDeviceID = peerDeviceID
        self.transport = transport
        self.clipboard = clipboard
        self.transfers = transfers
        self.policy = policy
    }

    public func currentPolicy() -> SyncPolicy { policy }

    public func peerCapabilities() -> CapsMessage? { announcedCapabilities }

    public func update(policy: SyncPolicy) {
        self.policy = policy
    }

    public func announceCapabilities() async throws {
        try await transport.send(.caps(policy.capsMessage))
    }

    public func handle(_ message: ControlMessage) async -> SyncEvent? {
        switch message {
        case .caps(let caps):
            announcedCapabilities = caps
            return nil
        case .clip(let clip):
            return await receive(clip)
        case .transferStart(let start):
            return await beginIncoming(start)
        case .transferEnd(let end):
            return await finishIncoming(end)
        case .transferAbort(let abort):
            return await handleAbort(abort)
        case .ack(let ack):
            return acknowledge(ack)
        default:
            return nil
        }
    }

    public func reset() async {
        for (transferID, clipID) in clipByTransfer {
            await transfers.abortIncoming(transferID, reason: .userCancelled)
            pending.removeValue(forKey: clipID)
        }
        for transferID in abortedOutgoing {
            await transfers.abortOutgoing(transferID, reason: .userCancelled)
        }
        clipByTransfer.removeAll()
        pending.removeAll()
        abortedOutgoing.removeAll()
    }

    func acknowledge(_ ack: AckMessage) -> SyncEvent? {
        guard !ack.applied else { return nil }
        return event(.clipRejected(ack.reason ?? .userCancelled), clipID: ack.id)
    }

    func event(_ kind: SyncEvent.Kind, clipID: ClipID?) -> SyncEvent {
        SyncEvent(peerDeviceID: peerDeviceID, kind: kind, clipID: clipID)
    }
}
