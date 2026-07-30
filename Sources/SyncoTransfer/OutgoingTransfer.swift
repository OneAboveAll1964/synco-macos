import Foundation
import SyncoCore

public actor OutgoingTransfer {
    public nonisolated let descriptor: TransferDescriptor
    public nonisolated let fileURL: URL

    private let chunkBytes: Int
    private var handle: FileHandle?
    private var sentBytes: Int64 = 0
    private var closed = false

    public init(
        descriptor: TransferDescriptor,
        fileURL: URL,
        chunkBytes: Int = SyncoConstants.Framing.maxBlobChunkBytes
    ) {
        self.descriptor = descriptor
        self.fileURL = fileURL
        self.chunkBytes = min(max(chunkBytes, 1), SyncoConstants.Framing.maxBlobChunkBytes)
    }

    public static func prepare(
        fileURL: URL,
        clipID: ClipID,
        transferID: TransferID = TransferID(),
        name: String? = nil,
        mime: String? = nil,
        relativePath: String? = nil
    ) throws -> OutgoingTransfer {
        let measurement = try FileMeasurement.measure(fileURL: fileURL)
        let descriptor = TransferDescriptor(
            transferID: transferID,
            clipID: clipID,
            name: TransferFileName.sanitized(name ?? fileURL.lastPathComponent),
            mime: mime ?? MIMEType.forFile(at: fileURL),
            size: measurement.size,
            sha256: measurement.sha256,
            relativePath: relativePath
        )
        return OutgoingTransfer(descriptor: descriptor, fileURL: fileURL)
    }

    public var sentByteCount: Int64 { sentBytes }

    public var isComplete: Bool { sentBytes >= descriptor.size }

    public var progress: TransferProgress {
        TransferProgress(
            descriptor: descriptor,
            direction: .outgoing,
            transferredBytes: sentBytes,
            state: .active
        )
    }

    public func nextChunk() throws -> BlobChunk? {
        guard !closed, sentBytes < descriptor.size else {
            cancel()
            return nil
        }
        let handle = try openedHandle()
        let remaining = descriptor.size - sentBytes
        let requested = Int(min(Int64(chunkBytes), remaining))
        guard let data = try handle.read(upToCount: requested), !data.isEmpty else {
            cancel()
            return nil
        }
        let chunk = BlobChunk(
            transferID: descriptor.transferID,
            offset: UInt64(sentBytes),
            data: data
        )
        sentBytes += Int64(data.count)
        if sentBytes >= descriptor.size { cancel() }
        return chunk
    }

    public func chunks() -> AsyncThrowingStream<BlobChunk, any Error> {
        AsyncThrowingStream(unfolding: { [weak self] in
            guard let self else { return nil }
            return try await self.nextChunk()
        })
    }

    public func cancel() {
        closed = true
        try? handle?.close()
        handle = nil
    }

    private func openedHandle() throws -> FileHandle {
        if let handle { return handle }
        let opened = try FileHandle(forReadingFrom: fileURL)
        try opened.seek(toOffset: UInt64(sentBytes))
        handle = opened
        return opened
    }
}
