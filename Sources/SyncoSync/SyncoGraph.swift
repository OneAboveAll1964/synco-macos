import Foundation
import SyncoClipboard
import SyncoCore
import SyncoCrypto
import SyncoDiscovery
import SyncoSettings
import SyncoTransfer
import SyncoTransport

public struct SyncoGraph: Sendable {
    public let identity: DeviceIdentity
    public let settings: SettingsStore
    public let state: SyncState
    public let engine: SyncEngine
    public let commands: SyncCommands
    public let transfers: TransferManager

    @MainActor
    public static func make(
        identityStore: IdentityKeychainStore = IdentityKeychainStore(),
        settings: SettingsStore = SettingsStore(),
        paths: TransferPaths = .shared
    ) async throws -> SyncoGraph {
        let identity = try identityStore.loadOrCreate()
        let document = await settings.snapshot()
        let state = SyncState()
        let limit = BlobSizeLimit(maxBytes: document.maxBlobBytes)
        let clipboard = ClipboardService(
            deviceID: identity.deviceID,
            reader: PasteboardReader(paths: paths, limit: limit)
        )
        let transfers = TransferManager(paths: paths, limit: limit)
        let pairing = PairingCoordinator(state: state, settings: settings)
        let registry = PeerRegistry(
            localDeviceID: identity.deviceID,
            document: document,
            factory: SessionFactory(
                identity: identity,
                settings: settings,
                pairingApproval: pairing
            ),
            dialer: SyncoDialer(),
            transfers: transfers,
            clipboard: clipboard,
            pairing: pairing,
            state: state,
            policies: PolicyExchange(localDeviceID: identity.deviceID, settings: settings)
        )
        await pairing.attach(reconnector: registry)
        let engine = SyncEngine(
            identity: identity,
            document: document,
            settings: settings,
            clipboard: clipboard,
            transfers: transfers,
            registry: registry,
            browser: BonjourBrowser(localDeviceID: identity.deviceID),
            pathMonitor: PathMonitorService(),
            state: state
        )
        state.apply(identity: LocalIdentitySnapshot(identity: identity, displayName: document.displayName))
        return SyncoGraph(
            identity: identity,
            settings: settings,
            state: state,
            engine: engine,
            commands: SyncCommands(
                engine: engine,
                registry: registry,
                pairing: pairing,
                settings: settings
            ),
            transfers: transfers
        )
    }
}
