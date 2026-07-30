import Foundation
import Network

public enum PeerLinkPlan: Hashable, Sendable {
    case dial(NWEndpoint)
    case awaitPeer
    case standby
    case unpaired

    public var endpoint: NWEndpoint? {
        guard case .dial(let endpoint) = self else { return nil }
        return endpoint
    }

    public var dials: Bool {
        endpoint != nil
    }
}
