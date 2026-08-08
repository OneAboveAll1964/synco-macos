import Foundation
import SyncoCore

public struct SettingsDocument: Codable, Hashable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var displayName: String
    public var launchAtLogin: Bool
    public var keepAwake: Bool
    public var keepAwakeWithLidClosed: Bool
    public var paused: Bool
    public var maxBlobBytes: Int64
    public var allowsAdbShizukuStart: Bool
    public var defaultPeerPolicy: PeerDirectionPolicy
    public var peers: [TrustedPeerRecord]
    public var peerPolicies: [String: PeerDirectionPolicy]

    public init(
        version: Int = SettingsDocument.currentVersion,
        displayName: String,
        launchAtLogin: Bool = false,
        keepAwake: Bool = false,
        keepAwakeWithLidClosed: Bool = false,
        paused: Bool = false,
        maxBlobBytes: Int64 = SyncoConstants.Limits.defaultMaxBlobBytes,
        allowsAdbShizukuStart: Bool = false,
        defaultPeerPolicy: PeerDirectionPolicy = .bidirectional,
        peers: [TrustedPeerRecord] = [],
        peerPolicies: [String: PeerDirectionPolicy] = [:]
    ) {
        self.version = version
        self.displayName = displayName
        self.launchAtLogin = launchAtLogin
        self.keepAwake = keepAwake
        self.keepAwakeWithLidClosed = keepAwakeWithLidClosed
        self.paused = paused
        self.maxBlobBytes = maxBlobBytes
        self.allowsAdbShizukuStart = allowsAdbShizukuStart
        self.defaultPeerPolicy = defaultPeerPolicy
        self.peers = peers
        self.peerPolicies = peerPolicies
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = SettingsDocument.makeDefault()
        version = try values.decodeIfPresent(Int.self, forKey: .version) ?? fallback.version
        displayName = try values.decodeIfPresent(String.self, forKey: .displayName) ?? fallback.displayName
        launchAtLogin = try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        keepAwake = try values.decodeIfPresent(Bool.self, forKey: .keepAwake) ?? false
        keepAwakeWithLidClosed = try values.decodeIfPresent(Bool.self, forKey: .keepAwakeWithLidClosed) ?? false
        paused = try values.decodeIfPresent(Bool.self, forKey: .paused) ?? false
        maxBlobBytes = try values.decodeIfPresent(Int64.self, forKey: .maxBlobBytes) ?? fallback.maxBlobBytes
        allowsAdbShizukuStart = try values.decodeIfPresent(Bool.self, forKey: .allowsAdbShizukuStart) ?? false
        defaultPeerPolicy = try values.decodeIfPresent(PeerDirectionPolicy.self, forKey: .defaultPeerPolicy)
            ?? fallback.defaultPeerPolicy
        peers = try values.decodeIfPresent([TrustedPeerRecord].self, forKey: .peers) ?? []
        peerPolicies = try values.decodeIfPresent([String: PeerDirectionPolicy].self, forKey: .peerPolicies) ?? [:]
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
            maxBlobBytes: maxBlobBytes,
            allowsAdbShizukuStart: allowsAdbShizukuStart
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
        case keepAwake
        case keepAwakeWithLidClosed
        case paused
        case maxBlobBytes
        case allowsAdbShizukuStart
        case defaultPeerPolicy
        case peers
        case peerPolicies
    }
}
