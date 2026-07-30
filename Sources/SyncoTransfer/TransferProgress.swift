import Foundation
import SyncoCore

public struct TransferProgress: Hashable, Sendable, Identifiable {
    public enum Direction: String, Hashable, Sendable, CaseIterable {
        case incoming
        case outgoing
    }

    public enum State: Hashable, Sendable {
        case active
        case completed
        case aborted(ClipRejectionReason)
    }

    public let transferID: TransferID
    public let clipID: ClipID
    public let name: String
    public let direction: Direction
    public let transferredBytes: Int64
    public let totalBytes: Int64
    public let state: State

    public var id: TransferID { transferID }

    public init(
        transferID: TransferID,
        clipID: ClipID,
        name: String,
        direction: Direction,
        transferredBytes: Int64,
        totalBytes: Int64,
        state: State
    ) {
        self.transferID = transferID
        self.clipID = clipID
        self.name = name
        self.direction = direction
        self.transferredBytes = transferredBytes
        self.totalBytes = totalBytes
        self.state = state
    }

    public init(
        descriptor: TransferDescriptor,
        direction: Direction,
        transferredBytes: Int64,
        state: State
    ) {
        self.init(
            transferID: descriptor.transferID,
            clipID: descriptor.clipID,
            name: descriptor.name,
            direction: direction,
            transferredBytes: transferredBytes,
            totalBytes: descriptor.size,
            state: state
        )
    }

    public var fraction: Double {
        guard totalBytes > 0 else { return state == .completed ? 1 : 0 }
        return min(1, max(0, Double(transferredBytes) / Double(totalBytes)))
    }

    public var isFinished: Bool {
        state != .active
    }

    public var rejectionReason: ClipRejectionReason? {
        guard case .aborted(let reason) = state else { return nil }
        return reason
    }
}
