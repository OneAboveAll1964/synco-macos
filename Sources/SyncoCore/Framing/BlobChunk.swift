import Foundation

public struct BlobChunk: Hashable, Sendable {
    public let transferID: TransferID
    public let offset: UInt64
    public let data: Data

    public init(transferID: TransferID, offset: UInt64, data: Data) {
        self.transferID = transferID
        self.offset = offset
        self.data = data
    }

    public func encodedBody() throws -> Data {
        guard data.count <= SyncoConstants.Framing.maxBlobChunkBytes else {
            throw SyncoError.blobChunkTooLarge(data.count)
        }
        var output = Data(capacity: SyncoConstants.Framing.blobChunkHeaderBytes + data.count)
        output.append(transferID.rawBytes)
        output.append(BigEndianBytes.encode(offset))
        output.append(data)
        return output
    }

    public func framePayload() throws -> FramePayload {
        .blobChunk(try encodedBody())
    }

    public static func decode(body: Data) throws -> BlobChunk {
        let headerBytes = SyncoConstants.Framing.blobChunkHeaderBytes
        guard body.count >= headerBytes else { throw SyncoError.malformedBlobChunk }
        let rebased = Data(body)
        let identifierBytes = rebased.prefix(SyncoConstants.Framing.transferIDBytes)
        let offsetBytes = rebased[SyncoConstants.Framing.transferIDBytes..<headerBytes]
        guard let transferID = TransferID(rawBytes: Data(identifierBytes)),
              let offset = BigEndianBytes.uint64(Data(offsetBytes))
        else {
            throw SyncoError.malformedBlobChunk
        }
        let payload = Data(rebased.dropFirst(headerBytes))
        guard payload.count <= SyncoConstants.Framing.maxBlobChunkBytes else {
            throw SyncoError.blobChunkTooLarge(payload.count)
        }
        return BlobChunk(transferID: transferID, offset: offset, data: payload)
    }

    public var endOffset: UInt64 { offset + UInt64(data.count) }
}
