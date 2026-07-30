import Foundation
import SyncoCore

public actor IncomingTransferRegistry {
    private let paths: TransferPaths
    private let progress: TransferProgressCenter
    private var limit: BlobSizeLimit
    private var transfers: [TransferID: IncomingTransfer] = [:]

    public init(paths: TransferPaths, progress: TransferProgressCenter, limit: BlobSizeLimit) {
        self.paths = paths
        self.progress = progress
        self.limit = limit
    }

    public func setLimit(_ newLimit: BlobSizeLimit) {
        limit = newLimit
    }

    public func identifiers() -> Set<TransferID> {
        Set(transfers.keys)
    }

    public func begin(_ descriptor: TransferDescriptor) async throws {
        guard transfers[descriptor.transferID] == nil else {
            throw SyncoError.malformedMessage(descriptor.transferID.stringValue)
        }
        try limit.require(descriptor.size)
        let transfer = try IncomingTransfer(descriptor: descriptor, paths: paths)
        transfers[descriptor.transferID] = transfer
        await progress.publish(
            TransferProgress(descriptor: descriptor, direction: .incoming, transferredBytes: 0, state: .active)
        )
    }

    public func accept(_ chunk: BlobChunk) async throws {
        guard let transfer = transfers[chunk.transferID] else { throw SyncoError.malformedBlobChunk }
        do {
            try await transfer.write(chunk)
        } catch {
            await abort(chunk.transferID, reason: TransferFailureReason.reason(for: error))
            throw error
        }
        await progress.publish(await transfer.progress)
    }

    public func complete(_ transferID: TransferID) async throws -> URL {
        guard let transfer = transfers.removeValue(forKey: transferID) else {
            throw SyncoError.malformedBlobChunk
        }
        do {
            let destination = try await transfer.finish()
            await publish(transfer.descriptor, state: .completed)
            return destination
        } catch {
            await transfer.discard()
            await publish(transfer.descriptor, state: .aborted(TransferFailureReason.reason(for: error)))
            throw error
        }
    }

    public func abort(_ transferID: TransferID, reason: ClipRejectionReason) async {
        guard let transfer = transfers.removeValue(forKey: transferID) else { return }
        await transfer.discard()
        await publish(transfer.descriptor, state: .aborted(reason))
    }

    public func abortAll(reason: ClipRejectionReason) async {
        for transferID in Array(transfers.keys) {
            await abort(transferID, reason: reason)
        }
    }

    private func publish(_ descriptor: TransferDescriptor, state: TransferProgress.State) async {
        await progress.publish(
            TransferProgress(
                descriptor: descriptor,
                direction: .incoming,
                transferredBytes: state == .completed ? descriptor.size : 0,
                state: state
            )
        )
    }
}
