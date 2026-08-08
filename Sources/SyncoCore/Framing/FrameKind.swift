import Foundation

public enum FrameKind: UInt8, Hashable, Sendable, CaseIterable {
    case control = 0x01
    case blobChunk = 0x02
    case media = 0x03
}
