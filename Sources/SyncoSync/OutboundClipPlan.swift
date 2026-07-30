import Foundation
import SyncoClipboard
import SyncoCore
import SyncoTransfer

public struct OutboundClipPlan: Sendable {
    public let representations: [ClipRepresentation]
    public let descriptors: [TransferDescriptor]
    public let sources: [TransferID: URL]

    public init(clip: LocalClip, permitted: [ClipRepresentation]) {
        var representations: [ClipRepresentation] = []
        var descriptors: [TransferDescriptor] = []
        var sources: [TransferID: URL] = [:]
        for representation in permitted {
            guard let originalID = representation.transferID else {
                representations.append(representation)
                continue
            }
            guard let source = clip.blobSource(for: originalID) else { continue }
            let transferID = TransferID()
            guard let rebound = Self.rebound(representation, transferID: transferID),
                  let descriptor = TransferDescriptor(representation: rebound, clipID: clip.id)
            else {
                continue
            }
            representations.append(rebound)
            descriptors.append(descriptor)
            sources[transferID] = source
        }
        self.representations = representations
        self.descriptors = descriptors
        self.sources = sources
    }

    public var isEmpty: Bool { representations.isEmpty }

    public var transferIDs: [TransferID] { descriptors.map(\.transferID) }

    private static func rebound(
        _ representation: ClipRepresentation,
        transferID: TransferID
    ) -> ClipRepresentation? {
        switch representation {
        case .image(let image):
            return .image(ClipImageRepresentation(
                mime: image.mime,
                name: image.name,
                size: image.size,
                sha256: image.sha256,
                transferID: transferID
            ))
        case .file(let file):
            return .file(ClipFileRepresentation(
                mime: file.mime,
                name: file.name,
                size: file.size,
                sha256: file.sha256,
                transferID: transferID,
                rel: file.rel
            ))
        default:
            return nil
        }
    }
}
