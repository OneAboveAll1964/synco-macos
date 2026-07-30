import Foundation
import SyncoCore

public struct PeerBinding: Sendable {
    public let deviceID: DeviceID
    public let router: ClipRouter

    public init(deviceID: DeviceID, router: ClipRouter) {
        self.deviceID = deviceID
        self.router = router
    }
}
