import Foundation
import SyncoCore
import SyncoCrypto

public struct PeerSessionConfiguration: Sendable {
    public let identity: DeviceIdentity
    public let displayName: String
    public let trustedPeers: any TrustedPeerProviding
    public let pairingApproval: any PairingApprovalProviding
    public let handshakeTimeout: Duration
    public let pairingTimeout: Duration
    public let pingInterval: Duration
    public let readTimeout: Duration

    public init(
        identity: DeviceIdentity,
        displayName: String,
        trustedPeers: any TrustedPeerProviding,
        pairingApproval: any PairingApprovalProviding,
        handshakeTimeout: Duration = SyncoConstants.Timing.readTimeout,
        pairingTimeout: Duration = SyncoConstants.Timing.pairTimeout,
        pingInterval: Duration = SyncoConstants.Timing.pingInterval,
        readTimeout: Duration = SyncoConstants.Timing.readTimeout
    ) {
        self.identity = identity
        self.displayName = displayName
        self.trustedPeers = trustedPeers
        self.pairingApproval = pairingApproval
        self.handshakeTimeout = handshakeTimeout
        self.pairingTimeout = pairingTimeout
        self.pingInterval = pingInterval
        self.readTimeout = readTimeout
    }

    var localHelloDisplayName: String {
        displayName.isEmpty ? identity.deviceID.rawValue : displayName
    }
}
