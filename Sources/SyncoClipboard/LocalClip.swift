import Foundation
import SyncoCore

public struct LocalClip: Hashable, Sendable, Identifiable {
    public let id: ClipID
    public let timestampMilliseconds: Int64
    public let origin: DeviceID
    public let hash: String
    public let representations: [ClipRepresentation]
    public let blobSources: [TransferID: URL]
    public let changeCount: Int

    public init(
        id: ClipID = ClipID(),
        timestampMilliseconds: Int64 = LocalClip.currentTimestamp(),
        origin: DeviceID,
        snapshot: PasteboardSnapshot
    ) {
        self.id = id
        self.timestampMilliseconds = timestampMilliseconds
        self.origin = origin
        hash = snapshot.canonicalHash
        representations = snapshot.representations
        blobSources = snapshot.blobSources
        changeCount = snapshot.changeCount
    }

    public var message: ClipMessage {
        message(representations: representations)
    }

    public func message(representations: [ClipRepresentation]) -> ClipMessage {
        ClipMessage(
            id: id,
            timestampMilliseconds: timestampMilliseconds,
            origin: origin,
            hash: ClipCanonicalHash.hexDigest(for: representations),
            representations: representations
        )
    }

    public func blobSource(for transferID: TransferID) -> URL? {
        blobSources[transferID]
    }

    public static func currentTimestamp() -> Int64 {
        Int64((Date().timeIntervalSince1970 * 1000).rounded())
    }
}
