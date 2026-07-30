import Foundation
import SyncoCore

public struct ClipRepresentationBundle: Hashable, Sendable {
    public private(set) var representations: [ClipRepresentation] = []
    public private(set) var blobSources: [TransferID: URL] = [:]

    public init() {}

    public var isEmpty: Bool { representations.isEmpty }

    public mutating func append(_ representation: ClipRepresentation) {
        representations.append(representation)
    }

    public mutating func appendBlob(
        _ representation: ClipRepresentation,
        transferID: TransferID,
        source: URL
    ) {
        representations.append(representation)
        blobSources[transferID] = source
    }

    public func snapshot(changeCount: Int) -> PasteboardSnapshot {
        PasteboardSnapshot(
            changeCount: changeCount,
            representations: representations,
            blobSources: blobSources
        )
    }
}
