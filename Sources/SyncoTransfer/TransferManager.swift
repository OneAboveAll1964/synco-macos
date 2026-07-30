import Foundation
import SyncoCore

public actor TransferManager {
    public nonisolated let paths: TransferPaths
    public nonisolated let progress: TransferProgressCenter

    private let incoming: IncomingTransferRegistry
    private let outgoing: OutgoingTransferRegistry
    private var limit: BlobSizeLimit

    public init(
        paths: TransferPaths = .shared,
        limit: BlobSizeLimit = .default,
        progress: TransferProgressCenter = TransferProgressCenter()
    ) {
        self.paths = paths
        self.progress = progress
        self.limit = limit
        incoming = IncomingTransferRegistry(paths: paths, progress: progress, limit: limit)
        outgoing = OutgoingTransferRegistry(progress: progress, limit: limit)
    }

    public var maxBlobBytes: Int64 { limit.maxBytes }

    public func setMaxBlobBytes(_ value: Int64) async {
        limit = BlobSizeLimit(maxBytes: value)
        await incoming.setLimit(limit)
        await outgoing.setLimit(limit)
    }

    public func allowsBlobSize(_ size: Int64) -> Bool {
        limit.allows(size)
    }

    public func beginIncoming(_ start: TransferStartMessage, relativePath: String? = nil) async throws {
        try await incoming.begin(TransferDescriptor(start: start, relativePath: relativePath))
    }

    public func beginIncoming(_ descriptor: TransferDescriptor) async throws {
        try await incoming.begin(descriptor)
    }

    public func acceptChunk(_ chunk: BlobChunk) async throws {
        try await incoming.accept(chunk)
    }

    public func completeIncoming(_ transferID: TransferID) async throws -> URL {
        try await incoming.complete(transferID)
    }

    public func abortIncoming(_ transferID: TransferID, reason: ClipRejectionReason) async {
        await incoming.abort(transferID, reason: reason)
    }

    public func registerOutgoing(descriptor: TransferDescriptor, fileURL: URL) async throws {
        try await outgoing.register(descriptor: descriptor, fileURL: fileURL)
    }

    public func prepareOutgoing(
        fileURL: URL,
        clipID: ClipID,
        transferID: TransferID = TransferID(),
        name: String? = nil,
        mime: String? = nil,
        relativePath: String? = nil
    ) async throws -> TransferDescriptor {
        try await outgoing.prepare(
            fileURL: fileURL,
            clipID: clipID,
            transferID: transferID,
            name: name,
            mime: mime,
            relativePath: relativePath
        )
    }

    public func nextOutgoingChunk(_ transferID: TransferID) async throws -> BlobChunk? {
        try await outgoing.nextChunk(transferID)
    }

    public func abortOutgoing(_ transferID: TransferID, reason: ClipRejectionReason) async {
        await outgoing.abort(transferID, reason: reason)
    }

    public func abort(_ transferID: TransferID, reason: ClipRejectionReason) async {
        await incoming.abort(transferID, reason: reason)
        await outgoing.abort(transferID, reason: reason)
    }

    public func progressStream() async -> AsyncStream<TransferProgress> {
        await progress.stream()
    }

    public func shutdown(reason: ClipRejectionReason = .userCancelled) async {
        await incoming.abortAll(reason: reason)
        await outgoing.abortAll(reason: reason)
        paths.removeStagingContents()
        await progress.finish()
    }
}
