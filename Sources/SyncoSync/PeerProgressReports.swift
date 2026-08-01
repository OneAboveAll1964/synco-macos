import Foundation
import SyncoCore

struct PeerProgressReports {
    static let minimumInterval: TimeInterval = 0.5

    private var lastSentAt: [TransferID: Date] = [:]

    mutating func shouldReport(_ transferID: TransferID, now: Date = Date()) -> Bool {
        if let last = lastSentAt[transferID], now.timeIntervalSince(last) < Self.minimumInterval {
            return false
        }
        lastSentAt[transferID] = now
        return true
    }

    mutating func forget(_ transferID: TransferID) {
        lastSentAt.removeValue(forKey: transferID)
    }
}
