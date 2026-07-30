import Foundation
import SyncoCore

public struct SettingsDocument: Codable, Hashable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var displayName: String
    public var launchAtLogin: Bool
    public var paused: Bool
    public var maxBlobBytes: Int64
    public var defaultPeerPolicy: PeerDirectionPolicy
    public var peers: [TrustedPeerRecord]
    public var peerPolicies: [String: PeerDirectionPolicy]

    public init(
        version: Int = SettingsDocument.currentVersion,
        displayName: String,
        launchAtLogin: Bool = false,
        paused: Bool = false,
        maxBlobBytes: Int64 = SyncoConstants.Limits.defaultMaxBlobBytes,
        defaultPeerPolicy: PeerDirectionPolicy = .bidirectional,
        peers: [TrustedPeerRecord] = [],
        peerPolicies: [String: PeerDirectionPolicy] = [:]
    ) {
        self.version = version
        self.displayName = displayName
        self.launchAtLogin = launchAtLogin
        self.paused = paused
        self.maxBlobBytes = maxBlobBytes
        self.defaultPeerPolicy = defaultPeerPolicy
        self.peers = peers
        self.peerPolicies = peerPolicies
    }

    public static func makeDefault() -> SettingsDocument {
        SettingsDocument(displayName: DeviceDisplayName.systemDefault)
    }

    public func peer(_ deviceID: DeviceID) -> TrustedPeerRecord? {
        peers.first { $0.deviceID == deviceID }
    }

    public func directionPolicy(for deviceID: DeviceID) -> PeerDirectionPolicy {
        peerPolicies[deviceID.rawValue] ?? defaultPeerPolicy
    }

    public func policy(for deviceID: DeviceID) -> SyncPolicy {
        SyncPolicy(
            direction: directionPolicy(for: deviceID),
            paused: paused,
            maxBlobBytes: maxBlobBytes
        )
    }

    public var trustedPeers: [TrustedPeerRecord] {
        peers.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    public mutating func upsert(_ record: TrustedPeerRecord) {
        if let index = peers.firstIndex(where: { $0.deviceID == record.deviceID }) {
            peers[index] = record
        } else {
            peers.append(record)
        }
    }

    public mutating func remove(_ deviceID: DeviceID) {
        peers.removeAll { $0.deviceID == deviceID }
        peerPolicies.removeValue(forKey: deviceID.rawValue)
    }

    enum CodingKeys: String, CodingKey {
        case version
        case displayName
        case launchAtLogin
        case paused
        case maxBlobBytes
        case defaultPeerPolicy
        case peers
        case peerPolicies
    }
}
