import Foundation
import SyncoCore

public struct BlobSizeLimit: Hashable, Sendable {
    public var maxBytes: Int64

    public static let `default` = BlobSizeLimit(maxBytes: SyncoConstants.Limits.defaultMaxBlobBytes)

    public init(maxBytes: Int64) {
        self.maxBytes = maxBytes
    }

    public func allows(_ size: Int64) -> Bool {
        size >= 0 && size <= maxBytes
    }

    public func require(_ size: Int64) throws {
        guard allows(size) else { throw SyncoError.transferAborted(.tooLarge) }
    }
}
