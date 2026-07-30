import Foundation

public enum FrameCodec {
    public static func encode(_ payload: Data, maxPayloadBytes: Int = SyncoConstants.Framing.maxPayloadBytes) throws -> Data {
        guard !payload.isEmpty else { throw SyncoError.invalidFrameLength(0) }
        guard payload.count <= maxPayloadBytes else { throw SyncoError.frameTooLarge(UInt32(payload.count)) }
        var output = Data(capacity: payload.count + SyncoConstants.Framing.lengthPrefixBytes)
        output.append(BigEndianBytes.encode(UInt32(payload.count)))
        output.append(payload)
        return output
    }

    public static func encode(_ payload: FramePayload) throws -> Data {
        try encode(payload.encoded())
    }

    public struct Decoder: Sendable {
        public let maxPayloadBytes: Int
        private var buffer: [UInt8] = []
        private var readIndex = 0

        public init(maxPayloadBytes: Int = SyncoConstants.Framing.maxPayloadBytes) {
            self.maxPayloadBytes = maxPayloadBytes
        }

        public var bufferedByteCount: Int { buffer.count - readIndex }

        public mutating func push(_ bytes: some Sequence<UInt8>) throws -> [Data] {
            buffer.append(contentsOf: bytes)
            var frames: [Data] = []
            while let frame = try nextFrame() {
                frames.append(frame)
            }
            return frames
        }

        public mutating func nextFrame() throws -> Data? {
            let prefixBytes = SyncoConstants.Framing.lengthPrefixBytes
            guard bufferedByteCount >= prefixBytes else {
                compact()
                return nil
            }
            var length: UInt32 = 0
            for offset in 0..<prefixBytes {
                length = length << 8 | UInt32(buffer[readIndex + offset])
            }
            guard length > 0 else { throw SyncoError.invalidFrameLength(length) }
            guard length <= UInt32(maxPayloadBytes) else { throw SyncoError.frameTooLarge(length) }
            let payloadLength = Int(length)
            guard bufferedByteCount - prefixBytes >= payloadLength else {
                compact()
                return nil
            }
            let start = readIndex + prefixBytes
            let payload = Data(buffer[start..<(start + payloadLength)])
            readIndex = start + payloadLength
            compact()
            return payload
        }

        private mutating func compact() {
            guard readIndex > 0 else { return }
            if readIndex == buffer.count {
                buffer.removeAll(keepingCapacity: true)
                readIndex = 0
            } else if readIndex >= SyncoConstants.Framing.maxBlobChunkBytes {
                buffer.removeFirst(readIndex)
                readIndex = 0
            }
        }
    }
}
