import Foundation
import SyncoCore
import SyncoSettings
import SyncoSync

extension AppViewModel {
    public func setDirectionChoice(_ choice: DirectionChoice) {
        Task {
            await self.commands.setPaused(choice.isPaused)
            guard let direction = choice.direction else { return }
            await self.commands.setDefaultDirection(direction)
        }
    }

    func setDirection(_ direction: SyncDirection, for deviceID: DeviceID) {
        Task { await self.commands.setDirection(direction, for: deviceID) }
    }

    func setSending(_ enabled: Bool, of category: ClipTypeCategory, for deviceID: DeviceID) {
        Task { await self.commands.setSending(enabled, of: category, for: deviceID) }
    }

    func setReceiving(_ enabled: Bool, of category: ClipTypeCategory, for deviceID: DeviceID) {
        Task { await self.commands.setReceiving(enabled, of: category, for: deviceID) }
    }

    func approvePairing(_ deviceID: DeviceID) {
        Task { await self.commands.approvePairing(deviceID) }
    }

    func rejectPairing(_ deviceID: DeviceID) {
        Task { await self.commands.rejectPairing(deviceID) }
    }

    func beginQRPairing(_ show: @escaping @MainActor (QRPairingCode) -> Void) {
        Task {
            guard let code = await self.commands.beginQRPairing() else { return }
            show(code)
        }
    }


    func beginPairing(with deviceID: DeviceID) {
        Task { await self.commands.beginPairing(with: deviceID) }
    }

    func forget(_ deviceID: DeviceID) {
        Task { await self.commands.forget(deviceID) }
    }

    func cancelTransfer(_ transferID: TransferID) {
        Task { await self.commands.cancelTransfer(transferID) }
    }

    func setDisplayName(_ displayName: String) {
        Task { await self.commands.setDisplayName(displayName) }
    }

    func setMaxBlobBytes(_ maxBlobBytes: Int64) {
        Task { await self.commands.setMaxBlobBytes(maxBlobBytes) }
    }

    func setAllowsAdbShizukuStart(_ allowed: Bool) {
        Task { await self.commands.setAllowsAdbShizukuStart(allowed) }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        Task { self.launchAtLoginStatus = await self.commands.setLaunchAtLogin(enabled) }
    }

    func refreshLaunchAtLogin() {
        Task { self.launchAtLoginStatus = await self.commands.reconcileLaunchAtLogin() }
    }

    func revealReceivedFolder() {
        FinderReveal.show(receivedDirectory)
    }

    func openLoginItemsSettings() {
        LaunchAtLogin.openLoginItemsSettings()
    }
}
