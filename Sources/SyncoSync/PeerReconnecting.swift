import Foundation
import SyncoCore

public protocol PeerReconnecting: Sendable {
    func reconnect(_ deviceID: DeviceID) async
}
