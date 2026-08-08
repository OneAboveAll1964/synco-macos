import Foundation
import SyncoClipboard
import SyncoCore
import SyncoCrypto
import SyncoDiscovery
import SyncoSettings
import SyncoTransfer
import SyncoTransport

public actor SyncEngine {
    public nonisolated let identity: DeviceIdentity

    let settings: SettingsStore
    let clipboard: ClipboardService
    let history: ClipHistoryStore
    let transfers: TransferManager
    let registry: PeerRegistry
    let browser: BonjourBrowser
    let pathMonitor: PathMonitorService
    let state: SyncState

    var document: SettingsDocument
    var listener: SyncoListener?
    var advertiser: BonjourAdvertiser?
    var tasks: [Task<Void, Never>] = []
    var browseTask: Task<Void, Never>?
    var pathSignature: String?
    var running = false

    init(
        identity: DeviceIdentity,
        document: SettingsDocument,
        settings: SettingsStore,
        clipboard: ClipboardService,
        transfers: TransferManager,
        registry: PeerRegistry,
        browser: BonjourBrowser,
        pathMonitor: PathMonitorService,
        state: SyncState,
        history: ClipHistoryStore
    ) {
        self.identity = identity
        self.document = document
        self.settings = settings
        self.clipboard = clipboard
        self.transfers = transfers
        self.registry = registry
        self.browser = browser
        self.pathMonitor = pathMonitor
        self.state = state
        self.history = history
    }

    public var isRunning: Bool { running }

    public var listeningPort: UInt16? { listener?.port }

    public func start() async {
        guard !running else { return }
        running = true
        await applyDocument(await settings.snapshot())
        guard await startNetworking() else {
            running = false
            await state.setRunning(false)
            return
        }
        startLoops()
        await state.setRunning(true)
    }

    public func stop() async {
        guard running else { return }
        running = false
        for task in tasks {
            task.cancel()
        }
        tasks.removeAll()
        browseTask?.cancel()
        browseTask = nil
        pathSignature = nil
        await clipboard.stop()
        await browser.stop()
        await pathMonitor.stop()
        await registry.closeAll(reason: .shutdown)
        await NetworkTeardown.run(advertiser: advertiser, listener: listener)
        advertiser = nil
        listener = nil
        await transfers.shutdown()
        await state.setRunning(false)
    }

    private func startNetworking() async -> Bool {
        do {
            let listener = try SyncoListener()
            let port = try await listener.start()
            self.listener = listener
            let advertiser = BonjourAdvertiser(
                listener: listener.nwListener,
                advertisement: ServiceAdvertisement(
                    deviceID: identity.deviceID,
                    displayName: document.displayName,
                    fingerprint: identity.fingerprint
                )
            )
            await advertiser.start()
            self.advertiser = advertiser
            await state.report(problem: nil)
            SyncoLog.session.info("synco listening on port \(port, privacy: .public)")
            return true
        } catch {
            await state.report(problem: .listenerUnavailable(String(describing: error)))
            SyncoLog.session.error("listener unavailable: \(String(describing: error), privacy: .public)")
            return false
        }
    }
}
