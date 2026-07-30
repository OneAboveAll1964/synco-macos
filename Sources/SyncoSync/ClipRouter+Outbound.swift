import Foundation
import SyncoClipboard
import SyncoCore
import SyncoTransfer

extension ClipRouter {
    public func send(_ clip: LocalClip) async -> SyncEvent? {
        let decision = OutboundClipPolicy.decide(
            representations: clip.representations,
            policy: policy,
            peerMaxBlobBytes: announcedCapabilities?.maxBlob
        )
        guard case .send(let permitted) = decision else {
            return event(.clipDropped, clipID: clip.id)
        }
        let plan = OutboundClipPlan(clip: clip, permitted: permitted)
        guard !plan.isEmpty else { return event(.clipDropped, clipID: clip.id) }
        await clipboard.noteSent(hash: clip.hash)
        do {
            try await register(plan)
            try await transport.send(.clip(clip.message(representations: plan.representations)))
            for descriptor in plan.descriptors {
                try await stream(descriptor)
            }
            return event(.clipSent, clipID: clip.id)
        } catch {
            await discard(plan, reason: TransferFailureReason.reason(for: error))
            return event(.clipFailed, clipID: clip.id)
        }
    }

    private func register(_ plan: OutboundClipPlan) async throws {
        for descriptor in plan.descriptors {
            guard let source = plan.sources[descriptor.transferID] else {
                throw SyncoError.transferAborted(.userCancelled)
            }
            try await transfers.registerOutgoing(descriptor: descriptor, fileURL: source)
        }
    }

    private func stream(_ descriptor: TransferDescriptor) async throws {
        let transferID = descriptor.transferID
        guard !abortedOutgoing.contains(transferID) else {
            abortedOutgoing.remove(transferID)
            return
        }
        try await transport.send(.transferStart(descriptor.startMessage))
        while !abortedOutgoing.contains(transferID) {
            guard let chunk = try await transfers.nextOutgoingChunk(transferID) else {
                try await transport.send(.transferEnd(TransferEndMessage(transferID: transferID, ok: true)))
                return
            }
            try await transport.send(chunk)
        }
        abortedOutgoing.remove(transferID)
        await transfers.abortOutgoing(transferID, reason: .userCancelled)
    }

    private func discard(_ plan: OutboundClipPlan, reason: ClipRejectionReason) async {
        for transferID in plan.transferIDs {
            abortedOutgoing.remove(transferID)
            await transfers.abortOutgoing(transferID, reason: reason)
        }
    }
}
