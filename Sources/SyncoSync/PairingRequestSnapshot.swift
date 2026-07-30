import Foundation
import SyncoCore
import SyncoTransport

public struct PairingRequestSnapshot: Identifiable, Hashable, Sendable {
    public let deviceID: DeviceID
    public let displayName: String
    public let platform: DevicePlatform
    public let fingerprint: Fingerprint
    public let requestedAt: Date

    public var id: DeviceID { deviceID }

    public init(
        deviceID: DeviceID,
        displayName: String,
        platform: DevicePlatform,
        fingerprint: Fingerprint,
        requestedAt: Date = Date()
    ) {
        self.deviceID = deviceID
        self.displayName = displayName
        self.platform = platform
        self.fingerprint = fingerprint
        self.requestedAt = requestedAt
    }

    public init(proposal: PairingProposal) {
        self.init(
            deviceID: proposal.deviceID,
            displayName: proposal.displayName,
            platform: proposal.platform,
            fingerprint: proposal.fingerprint
        )
    }
}
