import Foundation
import SyncoCore
import SyncoSettings

extension SyncCommands {
    public func setDirection(_ direction: SyncDirection, for deviceID: DeviceID) async {
        try? await settings.setDirectionPolicy(direction.policy, for: deviceID)
    }

    public func setDefaultDirection(_ direction: SyncDirection) async {
        try? await settings.setDefaultPeerPolicy(direction.policy)
    }

    public func setPolicy(_ policy: PeerDirectionPolicy, for deviceID: DeviceID) async {
        try? await settings.setDirectionPolicy(policy, for: deviceID)
    }

    public func setSending(
        _ enabled: Bool,
        of category: ClipTypeCategory,
        for deviceID: DeviceID
    ) async {
        var policy = await settings.snapshot().directionPolicy(for: deviceID)
        category.set(enabled, in: &policy.send)
        await setPolicy(policy, for: deviceID)
    }

    public func setReceiving(
        _ enabled: Bool,
        of category: ClipTypeCategory,
        for deviceID: DeviceID
    ) async {
        var policy = await settings.snapshot().directionPolicy(for: deviceID)
        category.set(enabled, in: &policy.receive)
        await setPolicy(policy, for: deviceID)
    }

    public func direction(for deviceID: DeviceID) async -> SyncDirection {
        SyncDirection(policy: await settings.snapshot().directionPolicy(for: deviceID))
    }
}
