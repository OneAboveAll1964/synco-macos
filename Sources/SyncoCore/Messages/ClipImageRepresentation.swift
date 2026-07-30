import Foundation

public struct ClipImageRepresentation: Codable, Hashable, Sendable {
    public let mime: String
    public let name: String
    public let size: Int64
    public let sha256: String
    public let transferID: TransferID

    public init(mime: String, name: String, size: Int64, sha256: String, transferID: TransferID) {
        self.mime = mime
        self.name = name
        self.size = size
        self.sha256 = sha256
        self.transferID = transferID
    }

    enum CodingKeys: String, CodingKey {
        case mime
        case name
        case size
        case sha256
        case transferID = "transferId"
    }
}
