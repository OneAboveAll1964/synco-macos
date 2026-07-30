import Foundation

public struct ClipMessage: Codable, Hashable, Sendable {
    public let id: ClipID
    public let timestampMilliseconds: Int64
    public let origin: DeviceID
    public let hash: String
    public let representations: [ClipRepresentation]

    public init(
        id: ClipID,
        timestampMilliseconds: Int64,
        origin: DeviceID,
        hash: String,
        representations: [ClipRepresentation]
    ) {
        self.id = id
        self.timestampMilliseconds = timestampMilliseconds
        self.origin = origin
        self.hash = hash
        self.representations = representations
    }

    public var blobTransferIDs: [TransferID] {
        representations.compactMap(\.transferID)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case timestampMilliseconds = "ts"
        case origin
        case hash
        case representations = "reps"
    }
}
