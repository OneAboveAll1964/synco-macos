import Foundation
import SyncoCore
import SyncoSettings

public actor PolicyExchange {
    private let localDeviceID: DeviceID
    private let settings: SettingsStore

    public init(localDeviceID: DeviceID, settings: SettingsStore) {
        self.localDeviceID = localDeviceID
        self.settings = settings
    }

    public func outgoing(for peer: DeviceID) async -> PolicyMessage {
        let policy = await settings.policy(for: peer)
        let directions = policy.direction
        return PolicyMessage(
            rev: directions.revision,
            send: directions.send,
            recv: directions.receive,
            paused: policy.paused,
            maxBlob: policy.maxBlobBytes
        )
    }

    @discardableResult
    public func adopt(_ message: PolicyMessage, from peer: DeviceID) async -> Bool {
        let mirrored = message.mirrored
        let candidate = PeerDirectionPolicy(
            send: mirrored.send,
            receive: mirrored.recv,
            revision: message.rev
        )
        let current = await settings.directionPolicy(for: peer)
        guard candidate.supersedes(current, ours: localDeviceID, theirs: peer) else {
            SyncoLog.settings.debug("ignored an older policy from a peer")
            return false
        }
        try? await settings.adoptDirectionPolicy(candidate, for: peer)
        try? await settings.setPaused(message.paused)
        try? await settings.setMaxBlobBytes(message.maxBlob)
        SyncoLog.settings.info("adopted the policy a peer sent")
        return true
    }
}
