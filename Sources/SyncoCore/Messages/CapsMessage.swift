import Foundation

public struct CapsMessage: Codable, Hashable, Sendable {
    public let accepts: ClipTypeFlags
    public let sends: ClipTypeFlags
    public let maxBlob: Int64
    public let adbShizuku: Bool

    public init(
        accepts: ClipTypeFlags,
        sends: ClipTypeFlags,
        maxBlob: Int64 = SyncoConstants.Limits.defaultMaxBlobBytes,
        adbShizuku: Bool = false
    ) {
        self.accepts = accepts
        self.sends = sends
        self.maxBlob = maxBlob
        self.adbShizuku = adbShizuku
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accepts = try container.decode(ClipTypeFlags.self, forKey: .accepts)
        sends = try container.decode(ClipTypeFlags.self, forKey: .sends)
        maxBlob = try container.decodeIfPresent(Int64.self, forKey: .maxBlob)
            ?? SyncoConstants.Limits.defaultMaxBlobBytes
        adbShizuku = try container.decodeIfPresent(Bool.self, forKey: .adbShizuku) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case accepts
        case sends
        case maxBlob
        case adbShizuku
    }
}
