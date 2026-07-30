import CryptoKit
import Foundation
import SyncoCore

public struct FileMeasurement: Hashable, Sendable {
    public let size: Int64
    public let sha256: String

    public init(size: Int64, sha256: String) {
        self.size = size
        self.sha256 = sha256
    }

    public init(data: Data) {
        size = Int64(data.count)
        sha256 = HexEncoding.encode(Data(SHA256.hash(data: data)))
    }

    public static func measure(
        fileURL: URL,
        chunkBytes: Int = SyncoConstants.Framing.maxBlobChunkBytes
    ) throws -> FileMeasurement {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        var hasher = SHA256()
        var total: Int64 = 0
        while let block = try handle.read(upToCount: chunkBytes), !block.isEmpty {
            hasher.update(data: block)
            total += Int64(block.count)
        }
        return FileMeasurement(size: total, sha256: HexEncoding.encode(Data(hasher.finalize())))
    }

    public func matches(digestHex: String) -> Bool {
        sha256.caseInsensitiveCompare(digestHex) == .orderedSame
    }
}
