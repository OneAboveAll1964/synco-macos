import Foundation
import SyncoCore

public enum SessionArbitration {
    public enum Resolution: String, Hashable, Sendable, CaseIterable {
        case adoptIncoming
        case rejectIncoming
    }

    public static func resolution(
        expected: SessionOrigin,
        existing: SessionOrigin?,
        incoming: SessionOrigin
    ) -> Resolution {
        guard let existing else { return .adoptIncoming }
        guard existing != expected, incoming == expected else { return .rejectIncoming }
        return .adoptIncoming
    }
}
