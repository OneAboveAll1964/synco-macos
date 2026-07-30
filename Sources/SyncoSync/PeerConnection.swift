import Foundation
import Network
import SyncoClipboard
import SyncoCore
import SyncoSettings
import SyncoTransfer
import SyncoTransport

public actor PeerConnection {
    public struct LinkState: Sendable {
        public let status: PeerLinkStatus
        public let capabilities: CapsMessage?
    }

    public nonisolated let deviceID: DeviceID
    public nonisolated let localDeviceID: DeviceID

    let registry: PeerRegistry
    let factory: SessionFactory
    let dialer: SyncoDialer
    let driver: SessionDriver
    let transfers: TransferManager
    let clipboard: any ClipboardApplying

    var policy: SyncPolicy
    var router: ClipRouter?
    var session: PeerSession?
    var origin: SessionOrigin?
    var endpoint: NWEndpoint?
    var status: PeerLinkStatus = .idle
    var dialTask: Task<Void, Never>?
    var dialGeneration = 0
    var dialing = false

    init(
        deviceID: DeviceID,
        localDeviceID: DeviceID,
        policy: SyncPolicy,
        registry: PeerRegistry,
        factory: SessionFactory,
        dialer: SyncoDialer,
        driver: SessionDriver,
        transfers: TransferManager,
        clipboard: any ClipboardApplying
    ) {
        self.deviceID = deviceID
        self.localDeviceID = localDeviceID
        self.policy = policy
        self.registry = registry
        self.factory = factory
        self.dialer = dialer
        self.driver = driver
        self.transfers = transfers
        self.clipboard = clipboard
    }

    public nonisolated var decision: DialDecision {
        DialDecision.decision(local: localDeviceID, peer: deviceID)
    }

    var isLive: Bool { origin != nil }

    func liveOrigin() -> SessionOrigin? { origin }

    func linkState() async -> LinkState {
        LinkState(status: status, capabilities: await router?.peerCapabilities())
    }

    func update(policy newPolicy: SyncPolicy) async {
        guard policy != newPolicy else { return }
        policy = newPolicy
        guard let router else { return }
        await router.update(policy: newPolicy)
        try? await router.announceCapabilities()
    }

    func dispatch(_ clip: LocalClip) {
        guard origin != nil, let router else { return }
        let registry = self.registry
        Task {
            guard let event = await router.send(clip) else { return }
            await registry.report(event)
        }
    }

    func cancelTransfer(_ transferID: TransferID) async {
        guard let router else { return }
        guard let event = await router.cancel(transferID) else { return }
        await registry.report(event)
    }

    func close(reason: CloseReason) async {
        stopDialing()
        endpoint = nil
        let closing = session
        await releaseSession()
        await closing?.close(reason: reason)
        status = .closed(reason)
    }
}
