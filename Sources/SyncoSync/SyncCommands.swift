import Foundation
import SyncoCore
import SyncoCrypto
import SyncoSettings

public struct SyncCommands: Sendable {
    let engine: SyncEngine
    let registry: PeerRegistry
    let pairing: PairingCoordinator
    let settings: SettingsStore
    let identity: DeviceIdentity

    init(
        engine: SyncEngine,
        registry: PeerRegistry,
        pairing: PairingCoordinator,
        settings: SettingsStore,
        identity: DeviceIdentity
    ) {
        self.engine = engine
        self.registry = registry
        self.pairing = pairing
        self.settings = settings
        self.identity = identity
    }

    public func beginQRPairing() async -> QRPairingCode? {
        guard let port = await engine.listeningPort else { return nil }
        let name = await settings.snapshot().displayName
        guard let code = QRPairing.code(
            identity: identity,
            displayName: name,
            hosts: LocalAddresses.ipv4(),
            port: port
        ) else {
            return nil
        }
        await pairing.armQRToken(code.token)
        return code
    }

    public func endQRPairing() async {
        await pairing.disarmQRToken()
    }

    public func start() async {
        await engine.start()
    }

    public func stop() async {
        await engine.stop()
    }

    public func setPaused(_ paused: Bool) async {
        try? await settings.setPaused(paused)
    }

    public func setDisplayName(_ displayName: String) async {
        try? await settings.setDisplayName(displayName)
    }

    public func setMaxBlobBytes(_ maxBlobBytes: Int64) async {
        try? await settings.setMaxBlobBytes(maxBlobBytes)
    }

    public func setAllowsAdbShizukuStart(_ allowed: Bool) async {
        try? await settings.setAllowsAdbShizukuStart(allowed)
    }

    @discardableResult
    public func setLaunchAtLogin(_ enabled: Bool) async -> LaunchAtLogin.Status {
        let status = (try? LaunchAtLogin.apply(enabled)) ?? .unavailable
        guard status.matches(enabled) else { return status }
        try? await settings.setLaunchAtLogin(enabled)
        return status
    }

    @discardableResult
    public func reconcileLaunchAtLogin() async -> LaunchAtLogin.Status {
        let wanted = await settings.snapshot().launchAtLogin
        let status = LaunchAtLogin.reconcile(wanted: wanted)
        if wanted, status == .disabled { try? await settings.setLaunchAtLogin(false) }
        return status
    }

    public func approvePairing(_ deviceID: DeviceID) async {
        await pairing.approve(deviceID)
    }

    public func rejectPairing(_ deviceID: DeviceID) async {
        await pairing.reject(deviceID)
    }

    public func beginPairing(with deviceID: DeviceID) async {
        await registry.beginPairing(with: deviceID)
    }

    public func forget(_ deviceID: DeviceID) async {
        try? await settings.forget(deviceID)
    }

    public func cancelTransfer(_ transferID: TransferID) async {
        await registry.cancelTransfer(transferID)
    }
}
