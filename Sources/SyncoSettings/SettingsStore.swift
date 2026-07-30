import Foundation
import SyncoCore
import SyncoCrypto

public actor SettingsStore {
    public nonisolated let updates: SettingsChangeBroadcaster

    private let storage: SettingsFileStorage
    private var document: SettingsDocument

    public init(
        storage: SettingsFileStorage = SettingsFileStorage(),
        broadcaster: SettingsChangeBroadcaster = SettingsChangeBroadcaster()
    ) {
        self.storage = storage
        updates = broadcaster
        document = storage.loadOrDefault()
    }

    public func snapshot() -> SettingsDocument { document }

    public func changes() async -> AsyncStream<SettingsDocument> {
        await updates.stream()
    }

    public func reload() async {
        let reloaded = storage.loadOrDefault()
        guard reloaded != document else { return }
        document = reloaded
        await updates.publish(reloaded)
    }

    public func policy(for deviceID: DeviceID) -> SyncPolicy {
        document.policy(for: deviceID)
    }

    public func isTrusted(_ deviceID: DeviceID) -> Bool {
        document.peer(deviceID)?.isUsable ?? false
    }

    public func staticPublicKey(for deviceID: DeviceID) -> Data? {
        guard let peer = document.peer(deviceID), peer.keyMatchesDeviceID else { return nil }
        return peer.staticPublicKey
    }

    public func trust(
        deviceID: DeviceID,
        staticPublicKey: Data,
        displayName: String,
        platform: DevicePlatform
    ) async throws -> TrustedPeerRecord {
        guard DeviceIdentity.staticPublicKey(staticPublicKey, matches: deviceID) else {
            throw SyncoError.didMismatch
        }
        let existing = document.peer(deviceID)
        let record = TrustedPeerRecord(
            deviceID: deviceID,
            staticPublicKey: staticPublicKey,
            displayName: DeviceDisplayName.truncated(displayName),
            platform: platform,
            firstPairedAt: existing?.firstPairedAt ?? Date(),
            rejected: false
        )
        try await mutate { $0.upsert(record) }
        return record
    }

    public func setRejected(_ rejected: Bool, for deviceID: DeviceID) async throws {
        try await mutate { document in
            guard var peer = document.peer(deviceID) else { return }
            peer.rejected = rejected
            document.upsert(peer)
        }
    }

    public func forget(_ deviceID: DeviceID) async throws {
        try await mutate { $0.remove(deviceID) }
    }

    public func setDirectionPolicy(_ policy: PeerDirectionPolicy, for deviceID: DeviceID) async throws {
        try await mutate { $0.peerPolicies[deviceID.rawValue] = policy }
    }

    public func setDefaultPeerPolicy(_ policy: PeerDirectionPolicy) async throws {
        try await mutate { $0.defaultPeerPolicy = policy }
    }

    public func setPaused(_ paused: Bool) async throws {
        try await mutate { $0.paused = paused }
    }

    public func setDisplayName(_ displayName: String) async throws {
        let sanitized = DeviceDisplayName.truncated(displayName)
        try await mutate { $0.displayName = sanitized }
    }

    public func setMaxBlobBytes(_ maxBlobBytes: Int64) async throws {
        let clamped = max(0, maxBlobBytes)
        try await mutate { $0.maxBlobBytes = clamped }
    }

    public func setLaunchAtLogin(_ enabled: Bool) async throws {
        try await mutate { $0.launchAtLogin = enabled }
    }

    private func mutate(_ change: (inout SettingsDocument) -> Void) async throws {
        var updated = document
        change(&updated)
        guard updated != document else { return }
        try storage.save(updated)
        document = updated
        await updates.publish(updated)
    }
}
