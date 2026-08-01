import Foundation
import Observation
import SyncoCore
import SyncoSettings
import SyncoSync
import SyncoTransfer

@MainActor
@Observable
public final class AppViewModel {
    public let state: SyncState
    public let receivedDirectory: URL
    public private(set) var document: SettingsDocument
    public internal(set) var launchAtLoginStatus: LaunchAtLogin.Status

    let commands: SyncCommands
    private let settings: SettingsStore
    private var observation: Task<Void, Never>?

    public init(
        state: SyncState,
        commands: SyncCommands,
        settings: SettingsStore,
        document: SettingsDocument,
        receivedDirectory: URL
    ) {
        self.state = state
        self.commands = commands
        self.settings = settings
        self.document = document
        self.receivedDirectory = receivedDirectory
        launchAtLoginStatus = LaunchAtLogin.status
    }

    public static func make(
        graph: SyncoGraph,
        paths: TransferPaths = .shared
    ) async -> AppViewModel {
        AppViewModel(
            state: graph.state,
            commands: graph.commands,
            settings: graph.settings,
            document: await graph.settings.snapshot(),
            receivedDirectory: paths.receivedDirectory
        )
    }

    public func begin() {
        guard observation == nil else { return }
        refreshLaunchAtLogin()
        observation = Task { [weak self] in
            guard let self else { return }
            for await updated in await self.settings.changes() {
                self.apply(updated)
            }
        }
    }

    public func end() {
        observation?.cancel()
        observation = nil
    }

    var summary: ConnectionSummary {
        ConnectionSummary(state: state)
    }

    public var directionChoice: DirectionChoice {
        DirectionChoice(
            direction: SyncDirection(policy: document.defaultPeerPolicy),
            paused: document.paused
        )
    }

    public var trustedPeers: [TrustedPeerRecord] {
        document.trustedPeers
    }

    var pairedPeers: [PeerSnapshot] {
        state.peers.filter(\.isTrusted)
    }

    var nearbyPeers: [PeerSnapshot] {
        state.peers.filter { !$0.isTrusted }
    }

    private func apply(_ updated: SettingsDocument) {
        document = updated
        launchAtLoginStatus = LaunchAtLogin.status
    }
}
