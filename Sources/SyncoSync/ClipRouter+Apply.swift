import Foundation
import SyncoCore

extension ClipRouter {
    func applyPending(_ entry: PendingInboundClip) async -> SyncEvent? {
        forget(entry)
        guard await clipboard.apply(entry.message, receivedFiles: entry.received) else {
            await respond(clipID: entry.clip.id, applied: false, reason: .userCancelled)
            return event(.clipRejected(.userCancelled), clipID: entry.clip.id)
        }
        await respond(clipID: entry.clip.id, applied: true, reason: nil)
        return event(.clipReceived, clipID: entry.clip.id)
    }

    func failClip(
        _ clipID: ClipID,
        reason: ClipRejectionReason,
        announcing transferID: TransferID?
    ) async -> SyncEvent? {
        if let transferID {
            try? await transport.send(
                .transferAbort(TransferAbortMessage(transferID: transferID, reason: reason))
            )
        }
        guard let entry = pending[clipID] else { return nil }
        forget(entry)
        for outstanding in entry.awaited {
            await transfers.abortIncoming(outstanding, reason: reason)
        }
        for destination in entry.received.values {
            try? FileManager.default.removeItem(at: destination)
        }
        await respond(clipID: clipID, applied: false, reason: reason)
        return event(.clipRejected(reason), clipID: clipID)
    }

    func respond(clipID: ClipID, applied: Bool, reason: ClipRejectionReason?) async {
        try? await transport.send(.ack(AckMessage(id: clipID, applied: applied, reason: reason)))
    }

    private func forget(_ entry: PendingInboundClip) {
        pending.removeValue(forKey: entry.clip.id)
        for transferID in entry.awaited {
            clipByTransfer.removeValue(forKey: transferID)
        }
        for transferID in entry.received.keys {
            clipByTransfer.removeValue(forKey: transferID)
        }
    }
}
