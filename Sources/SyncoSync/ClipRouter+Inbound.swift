import Foundation
import SyncoCore
import SyncoTransfer

extension ClipRouter {
    public func accept(_ chunk: BlobChunk) async -> SyncEvent? {
        guard let clipID = clipByTransfer[chunk.transferID] else { return nil }
        do {
            try await transfers.acceptChunk(chunk)
            return nil
        } catch {
            return await failClip(
                clipID,
                reason: TransferFailureReason.reason(for: error),
                announcing: chunk.transferID
            )
        }
    }

    public func cancel(_ transferID: TransferID) async -> SyncEvent? {
        abortedOutgoing.insert(transferID)
        await transfers.abortOutgoing(transferID, reason: .userCancelled)
        try? await transport.send(
            .transferAbort(TransferAbortMessage(transferID: transferID, reason: .userCancelled))
        )
        guard let clipID = clipByTransfer[transferID] else { return nil }
        return await failClip(clipID, reason: .userCancelled, announcing: nil)
    }

    func receive(_ clip: ClipMessage) async -> SyncEvent? {
        switch InboundClipDecision.decide(clip: clip, policy: policy, localDeviceID: localDeviceID) {
        case .ignore:
            return nil
        case .reject(let reason):
            await respond(clipID: clip.id, applied: false, reason: reason)
            return event(.clipRejected(reason), clipID: clip.id)
        case .accept(let representations):
            let entry = PendingInboundClip(clip: clip, representations: representations)
            guard !entry.isSatisfied else { return await applyPending(entry) }
            for transferID in entry.awaited {
                clipByTransfer[transferID] = clip.id
            }
            pending[clip.id] = entry
            return nil
        }
    }

    func beginIncoming(_ start: TransferStartMessage) async -> SyncEvent? {
        guard let entry = pending[start.clipID], entry.awaited.contains(start.transferID) else {
            try? await transport.send(
                .transferAbort(TransferAbortMessage(transferID: start.transferID, reason: .typeDisabled))
            )
            return nil
        }
        do {
            try await transfers.beginIncoming(
                start,
                relativePath: entry.relativePath(for: start.transferID)
            )
            return nil
        } catch {
            return await failClip(
                start.clipID,
                reason: TransferFailureReason.reason(for: error),
                announcing: start.transferID
            )
        }
    }

    func finishIncoming(_ end: TransferEndMessage) async -> SyncEvent? {
        guard let clipID = clipByTransfer[end.transferID] else { return nil }
        guard end.ok else { return await failClip(clipID, reason: .userCancelled, announcing: nil) }
        do {
            let destination = try await transfers.completeIncoming(end.transferID)
            clipByTransfer.removeValue(forKey: end.transferID)
            guard var entry = pending[clipID] else { return nil }
            entry.complete(end.transferID, url: destination)
            pending[clipID] = entry
            guard entry.isSatisfied else { return nil }
            return await applyPending(entry)
        } catch {
            return await failClip(
                clipID,
                reason: TransferFailureReason.reason(for: error),
                announcing: nil
            )
        }
    }

    func handleAbort(_ message: TransferAbortMessage) async -> SyncEvent? {
        abortedOutgoing.insert(message.transferID)
        await transfers.abortOutgoing(message.transferID, reason: message.reason)
        guard let clipID = clipByTransfer[message.transferID] else { return nil }
        return await failClip(clipID, reason: message.reason, announcing: nil)
    }
}
