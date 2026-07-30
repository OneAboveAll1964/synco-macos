import Foundation
import SyncoCore
import SyncoDiscovery
import SyncoSettings

public struct PeerSnapshot: Identifiable, Hashable, Sendable {
    public let deviceID: DeviceID
    public let displayName: String
    public let platform: DevicePlatform
    public let fingerprint: Fingerprint?
    public let status: PeerLinkStatus
    public let policy: PeerDirectionPolicy
    public let isTrusted: Bool
    public let isDiscovered: Bool
    public let lastSeen: Date?
    public let peerCapabilities: CapsMessage?

    public var id: DeviceID { deviceID }

    public init(
        deviceID: DeviceID,
        displayName: String,
        platform: DevicePlatform,
        fingerprint: Fingerprint?,
        status: PeerLinkStatus,
        policy: PeerDirectionPolicy,
        isTrusted: Bool,
        isDiscovered: Bool,
        lastSeen: Date?,
        peerCapabilities: CapsMessage?
    ) {
        self.deviceID = deviceID
        self.displayName = displayName
        self.platform = platform
        self.fingerprint = fingerprint
        self.status = status
        self.policy = policy
        self.isTrusted = isTrusted
        self.isDiscovered = isDiscovered
        self.lastSeen = lastSeen
        self.peerCapabilities = peerCapabilities
    }

    public init(
        trusted: SyncoSettings.TrustedPeerRecord,
        policy: PeerDirectionPolicy,
        status: PeerLinkStatus,
        discovered: DiscoveredPeer?,
        peerCapabilities: CapsMessage?
    ) {
        self.init(
            deviceID: trusted.deviceID,
            displayName: discovered?.displayName ?? trusted.displayName,
            platform: trusted.platform,
            fingerprint: trusted.fingerprint,
            status: status,
            policy: policy,
            isTrusted: trusted.isUsable,
            isDiscovered: discovered != nil,
            lastSeen: discovered?.lastSeen,
            peerCapabilities: peerCapabilities
        )
    }

    public init(discovered: DiscoveredPeer, policy: PeerDirectionPolicy) {
        self.init(
            deviceID: discovered.deviceID,
            displayName: discovered.displayName,
            platform: discovered.platform,
            fingerprint: discovered.fingerprint,
            status: .unpaired,
            policy: policy,
            isTrusted: false,
            isDiscovered: true,
            lastSeen: discovered.lastSeen,
            peerCapabilities: nil
        )
    }

    public var isOnline: Bool { status.isOnline }
}
