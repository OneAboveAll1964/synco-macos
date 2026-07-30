import Foundation
import SyncoCore

public struct InlineThreshold: Hashable, Sendable {
    public let maxEncodedBytes: Int

    public static let `default` = InlineThreshold(
        maxEncodedBytes: SyncoConstants.Limits.inlineRepresentationMaxBytes
    )

    public init(maxEncodedBytes: Int) {
        self.maxEncodedBytes = maxEncodedBytes
    }

    public func allows(text: String) -> Bool {
        text.utf8.count < maxEncodedBytes
    }

    public func allows(bytes: Data) -> Bool {
        Self.base64Length(of: bytes.count) < maxEncodedBytes
    }

    public static func base64Length(of byteCount: Int) -> Int {
        (byteCount + 2) / 3 * 4
    }
}
