import Foundation

public struct TransferProgressMessage: Codable, Hashable, Sendable {
    public let transferId: TransferID
    public let received: Int64

    public init(transferId: TransferID, received: Int64) {
        self.transferId = transferId
        self.received = received
    }

    enum CodingKeys: String, CodingKey {
        case transferId
        case received
    }
}
