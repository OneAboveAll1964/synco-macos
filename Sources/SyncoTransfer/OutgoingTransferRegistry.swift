import Foundation
import SyncoCore

public actor OutgoingTransferRegistry {
    private let progress: TransferProgressCenter
    private var limit: BlobSizeLimit
    private var transfers: [TransferID: OutgoingTransfer] = [:]

    public init(progress: TransferProgressCenter, limit: BlobSizeLimit) {
        self.progress = progress
        self.limit = limit
    }

    public func setLimit(_ newLimit: BlobSizeLimit) {
        limit = newLimit
    }

    public func identifiers() -> Set<TransferID> {
        Set(transfers.keys)
    }

    public func register(descriptor: TransferDescriptor, fileURL: URL) async throws {
        try limit.require(descriptor.size)
        guard transfers[descriptor.transferID] == nil else {
            throw SyncoError.malformedMessage(descriptor.transferID.stringValue)
        }
        transfers[descriptor.transferID] = OutgoingTransfer(descriptor: descriptor, fileURL: fileURL)
        await progress.publish(
            TransferProgress(descriptor: descriptor, direction: .outgoing, transferredBytes: 0, state: .active)
        )
    }

    public func prepare(
        fileURL: URL,
        clipID: ClipID,
        transferID: TransferID = TransferID(),
        name: String? = nil,
        mime: String? = nil,
        relativePath: String? = nil
    ) async throws -> TransferDescriptor {
        let transfer = try OutgoingTransfer.prepare(
            fileURL: fileURL,
            clipID: clipID,
            transferID: transferID,
            name: name,
            mime: mime,
            relativePath: relativePath
        )
        try limit.require(transfer.descriptor.size)
        transfers[transfer.descriptor.transferID] = transfer
        await progress.publish(await transfer.progress)
        return transfer.descriptor
    }

    public func nextChunk(_ transferID: TransferID) async throws -> BlobChunk? {
        guard let transfer = transfers[transferID] else { return nil }
        let chunk: BlobChunk?
        do {
            chunk = try await transfer.nextChunk()
        } catch {
            await abort(transferID, reason: TransferFailureReason.reason(for: error))
            throw error
        }
        guard let chunk else {
            transfers.removeValue(forKey: transferID)
            await publish(transfer.descriptor, state: .completed)
            return nil
        }
        await progress.publish(await transfer.progress)
        return chunk
    }

    public func abort(_ transferID: TransferID, reason: ClipRejectionReason) async {
        guard let transfer = transfers.removeValue(forKey: transferID) else { return }
        await transfer.cancel()
        await publish(transfer.descriptor, state: .aborted(reason))
    }

    public func abortAll(reason: ClipRejectionReason) async {
        for transferID in Array(transfers.keys) {
            await abort(transferID, reason: reason)
        }
    }

    func reportPeerProgress(_ transferID: TransferID, received: Int64) async {
        guard let transfer = transfers[transferID] else { return }
        await progress.publish(
            TransferProgress(
                descriptor: transfer.descriptor,
                direction: .outgoing,
                transferredBytes: received,
                state: .active
            )
        )
    }

    private func publish(_ descriptor: TransferDescriptor, state: TransferProgress.State) async {
        await progress.publish(
            TransferProgress(
                descriptor: descriptor,
                direction: .outgoing,
                transferredBytes: state == .completed ? descriptor.size : 0,
                state: state
            )
        )
    }
}
