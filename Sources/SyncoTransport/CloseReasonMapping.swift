import Foundation
import SyncoCore

enum CloseReasonMapping {
    static func reason(for error: any Error) -> CloseReason {
        if let syncoError = error as? SyncoError, let reason = syncoError.closeReason {
            return reason
        }
        if let transportError = error as? TransportError {
            return transportError.closeReason
        }
        if error is CancellationError {
            return .shutdown
        }
        return .shutdown
    }
}
