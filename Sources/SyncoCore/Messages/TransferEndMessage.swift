import Foundation

public struct TransferEndMessage: Codable, Hashable, Sendable {
    public let transferID: TransferID
    public let ok: Bool

    public init(transferID: TransferID, ok: Bool) {
        self.transferID = transferID
        self.ok = ok
    }

    enum CodingKeys: String, CodingKey {
        case transferID = "transferId"
        case ok
    }
}
