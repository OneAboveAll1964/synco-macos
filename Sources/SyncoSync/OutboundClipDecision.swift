import Foundation
import SyncoCore

public enum OutboundClipDecision: Hashable, Sendable {
    case send([ClipRepresentation])
    case drop

    public var representations: [ClipRepresentation] {
        guard case .send(let representations) = self else { return [] }
        return representations
    }

    public var isDropped: Bool {
        self == .drop
    }
}
