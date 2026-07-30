import Foundation
import SyncoCore
import SyncoCrypto
import SyncoSettings
import SyncoTransport

public struct SessionFactory: Sendable {
    let identity: DeviceIdentity
    let settings: SettingsStore
    let trustedPeers: any TrustedPeerProviding
    let pairingApproval: any PairingApprovalProviding

    init(
        identity: DeviceIdentity,
        settings: SettingsStore,
        pairingApproval: any PairingApprovalProviding
    ) {
        self.identity = identity
        self.settings = settings
        trustedPeers = SettingsTrustedPeers(settings: settings)
        self.pairingApproval = pairingApproval
    }

    func configuration() async -> PeerSessionConfiguration {
        PeerSessionConfiguration(
            identity: identity,
            displayName: await settings.snapshot().displayName,
            trustedPeers: trustedPeers,
            pairingApproval: pairingApproval
        )
    }

    func session(for connection: FramedConnection) async -> PeerSession {
        PeerSession(connection: connection, configuration: await configuration())
    }
}
