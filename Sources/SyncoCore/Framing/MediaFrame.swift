import Foundation

public struct MediaFrame: Hashable, Sendable {
    public static let keyframe: UInt8 = 0x01
    public static let config: UInt8 = 0x02
    public static let lastFragment: UInt8 = 0x04

    public static let headerBytes = 1 + 1 + 4 + 8

    public let stream: UInt8
    public let flags: UInt8
    public let seq: UInt32
    public let ptsMicros: UInt64
    public let data: Data

    public init(stream: UInt8, flags: UInt8, seq: UInt32, ptsMicros: UInt64, data: Data) {
        self.stream = stream
        self.flags = flags
        self.seq = seq
        self.ptsMicros = ptsMicros
        self.data = data
    }

    public var isKeyframe: Bool { flags & Self.keyframe != 0 }
    public var isConfig: Bool { flags & Self.config != 0 }
    public var isLastFragment: Bool { flags & Self.lastFragment != 0 }

    public func encoded() -> Data {
        var output = Data(capacity: Self.headerBytes + data.count)
        output.append(stream)
        output.append(flags)
        output.append(BigEndianBytes.encode(seq))
        output.append(BigEndianBytes.encode(ptsMicros))
        output.append(data)
        return output
    }

    public static func decode(_ body: Data) throws -> MediaFrame {
        guard body.count >= headerBytes else { throw SyncoError.malformedMediaFrame }
        let bytes = Data(body)
        let base = bytes.startIndex
        let stream = bytes[base]
        let flags = bytes[base + 1]
        guard let seq = BigEndianBytes.uint32(bytes.subdata(in: (base + 2)..<(base + 6))),
              let pts = BigEndianBytes.uint64(bytes.subdata(in: (base + 6)..<(base + 14)))
        else {
            throw SyncoError.malformedMediaFrame
        }
        return MediaFrame(
            stream: stream,
            flags: flags,
            seq: seq,
            ptsMicros: pts,
            data: bytes.subdata(in: (base + headerBytes)..<bytes.endIndex)
        )
    }
}
