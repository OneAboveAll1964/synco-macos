import Foundation
import SyncoSync
import SyncoTransfer

struct ConnectionSummary: Hashable, Sendable {
    let isRunning: Bool
    let isPaused: Bool
    let onlineCount: Int
    let pairedCount: Int
    let activeTransferCount: Int
    let hasProblem: Bool
    let hasPendingPairing: Bool

    @MainActor
    init(state: SyncState) {
        isRunning = state.isRunning
        isPaused = state.isPaused
        onlineCount = state.onlinePeers.count
        pairedCount = state.peers.filter(\.isTrusted).count
        activeTransferCount = state.transfers.count
        hasProblem = state.problem != nil
        hasPendingPairing = !state.pendingPairings.isEmpty
    }

    var headline: String {
        if hasProblem { return "Needs attention" }
        if hasPendingPairing { return "Pairing request waiting" }
        if !isRunning { return "Not running" }
        if isPaused { return "Paused" }
        if activeTransferCount > 0 {
            return activeTransferCount == 1
                ? "Transferring 1 item"
                : "Transferring \(activeTransferCount) items"
        }
        if onlineCount == 0 {
            return pairedCount == 0 ? "No devices paired yet" : "Waiting for devices"
        }
        return onlineCount == 1 ? "1 device connected" : "\(onlineCount) devices connected"
    }
}
