import Foundation
import SyncoCore

public protocol TrustedPeerProviding: Sendable {
    func trustedPeer(for deviceID: DeviceID) async -> TrustedPeerRecord?
}
