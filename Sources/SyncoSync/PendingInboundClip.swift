import Foundation
import SyncoCore

public struct PendingInboundClip: Sendable {
    public let clip: ClipMessage
    public let representations: [ClipRepresentation]
    public private(set) var awaited: Set<TransferID>
    public private(set) var received: [TransferID: URL]
    public private(set) var failed: Set<TransferID>
    public private(set) var failureReason: ClipRejectionReason?

    public init(clip: ClipMessage, representations: [ClipRepresentation]) {
        self.clip = clip
        self.representations = representations
        awaited = Set(representations.compactMap(\.transferID))
        received = [:]
        failed = []
    }

    public var isSatisfied: Bool { awaited.isEmpty }

    public var usableRepresentations: [ClipRepresentation] {
        representations.filter { representation in
            representation.transferID.map { !failed.contains($0) } ?? true
        }
    }

    public var hasUsableContent: Bool { !usableRepresentations.isEmpty }

    public var message: ClipMessage {
        ClipMessage(
            id: clip.id,
            timestampMilliseconds: clip.timestampMilliseconds,
            origin: clip.origin,
            hash: clip.hash,
            representations: usableRepresentations
        )
    }

    public mutating func complete(_ transferID: TransferID, url: URL) {
        awaited.remove(transferID)
        received[transferID] = url
    }

    public mutating func fail(_ transferID: TransferID, reason: ClipRejectionReason) {
        awaited.remove(transferID)
        failed.insert(transferID)
        failureReason = failureReason ?? reason
    }

    public func relativePath(for transferID: TransferID) -> String? {
        for representation in representations {
            guard case .file(let file) = representation, file.transferID == transferID else { continue }
            return file.rel
        }
        return nil
    }
}
