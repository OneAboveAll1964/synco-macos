import Foundation

public struct TransferAbortMessage: Codable, Hashable, Sendable {
    public let transferID: TransferID
    public let reason: ClipRejectionReason

    public init(transferID: TransferID, reason: ClipRejectionReason) {
        self.transferID = transferID
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey {
        case transferID = "transferId"
        case reason
    }
}
