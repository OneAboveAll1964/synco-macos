import Foundation
import SyncoCore

public struct MediaFrameFragmenter: Sendable {
    public let maxFragmentBytes: Int
    private let stream: UInt8

    public init(stream: UInt8 = 0, maxFragmentBytes: Int = defaultMaxFragmentBytes) {
        self.stream = stream
        self.maxFragmentBytes = max(1, maxFragmentBytes)
    }

    public func fragments(
        for picture: EncodedPicture,
        seq: UInt32
    ) -> [MediaFrame] {
        let payload = picture.data
        guard !payload.isEmpty else {
            return [frame(seq: seq, picture: picture, chunk: Data(), isLast: true)]
        }
        var frames: [MediaFrame] = []
        var offset = payload.startIndex
        while offset < payload.endIndex {
            let end = payload.index(offset, offsetBy: maxFragmentBytes, limitedBy: payload.endIndex) ?? payload.endIndex
            let isLast = end == payload.endIndex
            frames.append(frame(seq: seq, picture: picture, chunk: payload[offset..<end], isLast: isLast))
            offset = end
        }
        return frames
    }

    private func frame(seq: UInt32, picture: EncodedPicture, chunk: Data, isLast: Bool) -> MediaFrame {
        var flags: UInt8 = 0
        if picture.isKeyframe { flags |= MediaFrame.keyframe }
        if picture.isConfig { flags |= MediaFrame.config }
        if isLast { flags |= MediaFrame.lastFragment }
        return MediaFrame(
            stream: stream,
            flags: flags,
            seq: seq,
            ptsMicros: picture.ptsMicros,
            data: Data(chunk)
        )
    }

    public static let defaultMaxFragmentBytes =
        SyncoConstants.Framing.maxPayloadBytes - MediaFrame.headerBytes - 1
}
