import Foundation

public struct TransferStartMessage: Codable, Hashable, Sendable {
    public let transferID: TransferID
    public let clipID: ClipID
    public let name: String
    public let mime: String
    public let size: Int64
    public let sha256: String

    public init(
        transferID: TransferID,
        clipID: ClipID,
        name: String,
        mime: String,
        size: Int64,
        sha256: String
    ) {
        self.transferID = transferID
        self.clipID = clipID
        self.name = name
        self.mime = mime
        self.size = size
        self.sha256 = sha256
    }

    enum CodingKeys: String, CodingKey {
        case transferID = "transferId"
        case clipID = "clipId"
        case name
        case mime
        case size
        case sha256
    }
}
