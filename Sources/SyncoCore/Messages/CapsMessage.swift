import Foundation

public struct CapsMessage: Codable, Hashable, Sendable {
    public let accepts: ClipTypeFlags
    public let sends: ClipTypeFlags
    public let maxBlob: Int64

    public init(
        accepts: ClipTypeFlags,
        sends: ClipTypeFlags,
        maxBlob: Int64 = SyncoConstants.Limits.defaultMaxBlobBytes
    ) {
        self.accepts = accepts
        self.sends = sends
        self.maxBlob = maxBlob
    }

    enum CodingKeys: String, CodingKey {
        case accepts
        case sends
        case maxBlob
    }
}
