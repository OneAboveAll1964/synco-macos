import Foundation
import Observation
import SyncoCore
import SyncoTransfer

@MainActor
@Observable
public final class SyncState {
    public private(set) var identity: LocalIdentitySnapshot?
    public private(set) var peers: [PeerSnapshot] = []
    public private(set) var pendingPairings: [PairingRequestSnapshot] = []
    public private(set) var transfers: [TransferProgress] = []
    public private(set) var lastEvent: SyncEvent?
    public private(set) var problem: SyncPermissionProblem?
    public private(set) var isRunning = false
    public private(set) var isPaused = false

    public init() {}

    public var onlinePeers: [PeerSnapshot] {
        peers.filter(\.isOnline)
    }

    public func peer(_ deviceID: DeviceID) -> PeerSnapshot? {
        peers.first { $0.deviceID == deviceID }
    }

    public func apply(identity: LocalIdentitySnapshot) {
        self.identity = identity
    }

    public func apply(peers: [PeerSnapshot]) {
        self.peers = peers.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    public func apply(_ progress: TransferProgress) {
        var updated = transfers.filter { $0.transferID != progress.transferID }
        if !progress.isFinished {
            updated.append(progress)
        }
        transfers = updated.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func clearTransfers() {
        transfers.removeAll()
    }

    public func record(_ event: SyncEvent) {
        lastEvent = event
    }

    public func present(_ request: PairingRequestSnapshot) {
        var updated = pendingPairings.filter { $0.deviceID != request.deviceID }
        updated.append(request)
        pendingPairings = updated.sorted { $0.requestedAt < $1.requestedAt }
    }

    public func dismissPairing(_ deviceID: DeviceID) {
        pendingPairings.removeAll { $0.deviceID == deviceID }
    }

    public func report(problem: SyncPermissionProblem?) {
        self.problem = problem
    }

    public func setRunning(_ running: Bool) {
        isRunning = running
        if !running {
            transfers.removeAll()
        }
    }

    public func setPaused(_ paused: Bool) {
        isPaused = paused
    }
}
