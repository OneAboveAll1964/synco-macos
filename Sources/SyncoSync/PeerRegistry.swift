import Foundation
import SyncoCore
import SyncoDiscovery
import SyncoSettings
import SyncoTransfer
import SyncoTransport

public actor PeerRegistry {
    public nonisolated let localDeviceID: DeviceID

    let reconciliation: PeerReconciliation
    let factory: SessionFactory
    let dialer: SyncoDialer
    let transfers: TransferManager
    let clipboard: any ClipboardApplying
    let pairing: PairingCoordinator
    let state: SyncState

    var document: SettingsDocument
    var connections: [DeviceID: PeerConnection] = [:]
    var discovered: [DeviceID: DiscoveredPeer] = [:]
    var backoffs: [DeviceID: Backoff] = [:]
    var inboundTasks: [UUID: Task<Void, Never>] = [:]
    var pairingTasks: [DeviceID: Task<Void, Never>] = [:]

    init(
        localDeviceID: DeviceID,
        document: SettingsDocument,
        factory: SessionFactory,
        dialer: SyncoDialer,
        transfers: TransferManager,
        clipboard: any ClipboardApplying,
        pairing: PairingCoordinator,
        state: SyncState
    ) {
        self.localDeviceID = localDeviceID
        reconciliation = PeerReconciliation(localDeviceID: localDeviceID)
        self.document = document
        self.factory = factory
        self.dialer = dialer
        self.transfers = transfers
        self.clipboard = clipboard
        self.pairing = pairing
        self.state = state
    }

    var driver: SessionDriver {
        SessionDriver(registry: self, pairing: pairing)
    }

    public func dialDecision(for deviceID: DeviceID) -> DialDecision {
        reconciliation.decision(for: deviceID)
    }

    public func bind(
        descriptor: PeerDescriptor,
        session: PeerSession,
        origin: SessionOrigin
    ) async -> PeerBinding? {
        guard document.peer(descriptor.deviceID)?.isUsable ?? false else { return nil }
        let link = connection(for: descriptor.deviceID)
        let resolution = SessionArbitration.resolution(
            expected: reconciliation.expectedOrigin(for: descriptor.deviceID),
            existing: await link.liveOrigin(),
            incoming: origin
        )
        guard resolution == .adoptIncoming else { return nil }
        resetRetryDelay(for: descriptor.deviceID)
        let router = await link.adopt(
            session: session,
            origin: origin,
            policy: document.policy(for: descriptor.deviceID)
        )
        await refreshPeers()
        return PeerBinding(deviceID: descriptor.deviceID, router: router)
    }

    public func sessionEnded(
        deviceID: DeviceID?,
        origin: SessionOrigin,
        reason: CloseReason
    ) async {
        guard let deviceID, let link = connections[deviceID] else { return }
        await link.sessionEnded(origin: origin, reason: reason)
        if reason != .shutdown, reason != .unpaired {
            await state.record(SyncEvent(peerDeviceID: deviceID, kind: .linkFailed(reason)))
        }
        await refreshPeers()
    }
}
