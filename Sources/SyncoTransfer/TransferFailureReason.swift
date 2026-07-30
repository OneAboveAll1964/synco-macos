import Foundation
import SyncoCore

public enum TransferFailureReason {
    public static func reason(for error: any Error) -> ClipRejectionReason {
        guard let syncoError = error as? SyncoError else { return fileSystemReason(error) }
        switch syncoError {
        case .transferAborted(let reason): return reason
        case .hashMismatch: return .hashMismatch
        case .blobChunkTooLarge, .frameTooLarge: return .tooLarge
        case .malformedBlobChunk: return .hashMismatch
        default: return .userCancelled
        }
    }

    private static func fileSystemReason(_ error: any Error) -> ClipRejectionReason {
        let code = (error as NSError).code
        guard (error as NSError).domain == NSCocoaErrorDomain else { return .userCancelled }
        return code == NSFileWriteOutOfSpaceError ? .tooLarge : .userCancelled
    }
}
