import Foundation
import SyncoCore

public struct PeerDescriptor: Hashable, Sendable {
    public let deviceID: DeviceID
    public let displayName: String
    public let platform: DevicePlatform

    public init(deviceID: DeviceID, displayName: String, platform: DevicePlatform) {
        self.deviceID = deviceID
        self.displayName = displayName
        self.platform = platform
    }

    init(hello: HelloMessage) {
        self.init(
            deviceID: hello.deviceID,
            displayName: hello.displayName,
            platform: hello.platform
        )
    }
}
