import CryptoKit
import Foundation
import SyncoCore

public actor IncomingTransfer {
    public nonisolated let descriptor: TransferDescriptor
    public nonisolated let temporaryURL: URL

    private let paths: TransferPaths
    private var handle: FileHandle?
    private var hasher = SHA256()
    private var writtenBytes: Int64 = 0
    private var closed = false

    public init(descriptor: TransferDescriptor, paths: TransferPaths) throws {
        self.descriptor = descriptor
        self.paths = paths
        temporaryURL = try paths.stagingFile(named: "\(descriptor.transferID.stringValue).part")
        try Data().write(to: temporaryURL, options: .atomic)
        handle = try FileHandle(forWritingTo: temporaryURL)
    }

    public var receivedByteCount: Int64 { writtenBytes }

    public var isComplete: Bool { writtenBytes == descriptor.size }

    public var progress: TransferProgress {
        TransferProgress(
            descriptor: descriptor,
            direction: .incoming,
            transferredBytes: writtenBytes,
            state: .active
        )
    }

    public func write(_ chunk: BlobChunk) throws {
        guard !closed, let handle else { throw SyncoError.transferAborted(.userCancelled) }
        guard chunk.transferID == descriptor.transferID else { throw SyncoError.malformedBlobChunk }
        guard chunk.offset == UInt64(writtenBytes) else { throw SyncoError.malformedBlobChunk }
        guard chunk.data.count <= SyncoConstants.Framing.maxBlobChunkBytes else {
            throw SyncoError.blobChunkTooLarge(chunk.data.count)
        }
        let projected = writtenBytes + Int64(chunk.data.count)
        guard projected <= descriptor.size else { throw SyncoError.transferAborted(.tooLarge) }
        try handle.write(contentsOf: chunk.data)
        hasher.update(data: chunk.data)
        writtenBytes = projected
    }

    public func finish() throws -> URL {
        guard !closed else { throw SyncoError.transferAborted(.userCancelled) }
        closeHandle()
        guard writtenBytes == descriptor.size else {
            removeTemporaryFile()
            throw SyncoError.hashMismatch
        }
        let measurement = FileMeasurement(
            size: writtenBytes,
            sha256: HexEncoding.encode(Data(hasher.finalize()))
        )
        guard measurement.matches(digestHex: descriptor.sha256) else {
            let identifier = descriptor.transferID.stringValue
            removeTemporaryFile()
            SyncoLog.transfer.error("digest mismatch on transfer \(identifier, privacy: .public)")
            throw SyncoError.hashMismatch
        }
        let directory = try paths.prepareReceivedDirectory(relativePath: descriptor.relativePath)
        let destination = TransferFileName.availableURL(in: directory, name: descriptor.name)
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return destination
    }

    public func discard() {
        closeHandle()
        removeTemporaryFile()
    }

    private func closeHandle() {
        closed = true
        try? handle?.close()
        handle = nil
    }

    private func removeTemporaryFile() {
        try? FileManager.default.removeItem(at: temporaryURL)
    }
}
