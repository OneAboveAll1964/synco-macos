import Foundation

public enum SyncoError: Error, Hashable, Sendable {
    case invalidBase32(String)
    case invalidHexadecimal(String)
    case invalidDeviceID(String)
    case invalidFingerprint(String)
    case invalidFrameLength(UInt32)
    case frameTooLarge(UInt32)
    case emptyFramePayload
    case unknownFrameKind(UInt8)
    case malformedMediaFrame
    case malformedBlobChunk
    case blobChunkTooLarge(Int)
    case malformedRecord
    case malformedMessage(String)
    case versionMismatch(Int)
    case selfConnection
    case unknownKey
    case didMismatch
    case badHandshake
    case badAuth
    case invalidIdentityKey
    case replay
    case nonceExhausted
    case timeout
    case duplicateSession
    case unpaired
    case shutdown
    case hashMismatch
    case transferAborted(ClipRejectionReason)
    case keychain(status: Int32)

    public var closeReason: CloseReason? {
        switch self {
        case .invalidFrameLength, .frameTooLarge: return .frameTooLarge
        case .versionMismatch: return .versionMismatch
        case .selfConnection: return .selfConnection
        case .unknownKey: return .unknownKey
        case .didMismatch: return .didMismatch
        case .badHandshake, .nonceExhausted: return .badHandshake
        case .badAuth: return .badAuth
        case .replay, .malformedRecord: return .replay
        case .timeout: return .timeout
        case .duplicateSession: return .duplicateSession
        case .unpaired: return .unpaired
        case .shutdown: return .shutdown
        default: return nil
        }
    }
}
