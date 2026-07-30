import Foundation
import SyncoCore

public enum DiscoveryEvent: Hashable, Sendable {
    case peerAppeared(DiscoveredPeer)
    case peerChanged(DiscoveredPeer)
    case peerDisappeared(DeviceID)

    public var deviceID: DeviceID {
        switch self {
        case .peerAppeared(let peer), .peerChanged(let peer):
            return peer.deviceID
        case .peerDisappeared(let deviceID):
            return deviceID
        }
    }

    public var peer: DiscoveredPeer? {
        switch self {
        case .peerAppeared(let peer), .peerChanged(let peer):
            return peer
        case .peerDisappeared:
            return nil
        }
    }
}
