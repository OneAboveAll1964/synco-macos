import Foundation
import SyncoCore

public struct PasteboardSnapshot: Hashable, Sendable {
    public let changeCount: Int
    public let representations: [ClipRepresentation]
    public let blobSources: [TransferID: URL]

    public static let empty = PasteboardSnapshot(changeCount: 0, representations: [], blobSources: [:])

    public init(
        changeCount: Int,
        representations: [ClipRepresentation],
        blobSources: [TransferID: URL]
    ) {
        self.changeCount = changeCount
        self.representations = representations
        self.blobSources = blobSources
    }

    public var isEmpty: Bool { representations.isEmpty }

    public var canonicalHash: String {
        ClipCanonicalHash.hexDigest(for: representations)
    }

    public func blobSource(for transferID: TransferID) -> URL? {
        blobSources[transferID]
    }
}
