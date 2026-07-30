import Foundation
import SyncoCore
import SyncoSettings
import SyncoTransport

struct SettingsTrustedPeers: TrustedPeerProviding {
    let settings: SettingsStore

    func trustedPeer(for deviceID: DeviceID) async -> SyncoTransport.TrustedPeerRecord? {
        guard let record = await settings.snapshot().peer(deviceID), record.isUsable else {
            return nil
        }
        return SyncoTransport.TrustedPeerRecord(
            deviceID: record.deviceID,
            staticPublicKey: record.staticPublicKey,
            displayName: record.displayName,
            platform: record.platform
        )
    }
}
