import Foundation

public struct FramePayload: Hashable, Sendable {
    public let kind: FrameKind
    public let body: Data

    public init(kind: FrameKind, body: Data) {
        self.kind = kind
        self.body = body
    }

    public static func control(_ json: Data) -> FramePayload {
        FramePayload(kind: .control, body: json)
    }

    public static func blobChunk(_ body: Data) -> FramePayload {
        FramePayload(kind: .blobChunk, body: body)
    }

    public func encoded() -> Data {
        var output = Data(capacity: body.count + 1)
        output.append(kind.rawValue)
        output.append(body)
        return output
    }

    public static func decode(_ payload: Data) throws -> FramePayload {
        guard let first = payload.first else { throw SyncoError.emptyFramePayload }
        guard let kind = FrameKind(rawValue: first) else { throw SyncoError.unknownFrameKind(first) }
        return FramePayload(kind: kind, body: Data(payload.dropFirst()))
    }
}
