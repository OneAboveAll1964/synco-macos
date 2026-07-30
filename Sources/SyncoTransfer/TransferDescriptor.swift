import Foundation
import SyncoCore

public struct TransferDescriptor: Hashable, Sendable, Identifiable {
    public let transferID: TransferID
    public let clipID: ClipID
    public let name: String
    public let mime: String
    public let size: Int64
    public let sha256: String
    public let relativePath: String?

    public var id: TransferID { transferID }

    public init(
        transferID: TransferID,
        clipID: ClipID,
        name: String,
        mime: String,
        size: Int64,
        sha256: String,
        relativePath: String? = nil
    ) {
        self.transferID = transferID
        self.clipID = clipID
        self.name = name
        self.mime = mime
        self.size = size
        self.sha256 = sha256
        self.relativePath = relativePath
    }

    public init(start: TransferStartMessage, relativePath: String? = nil) {
        self.init(
            transferID: start.transferID,
            clipID: start.clipID,
            name: start.name,
            mime: start.mime,
            size: start.size,
            sha256: start.sha256,
            relativePath: relativePath
        )
    }

    public init(file: ClipFileRepresentation, clipID: ClipID) {
        self.init(
            transferID: file.transferID,
            clipID: clipID,
            name: file.name,
            mime: file.mime,
            size: file.size,
            sha256: file.sha256,
            relativePath: file.rel
        )
    }

    public init(image: ClipImageRepresentation, clipID: ClipID) {
        self.init(
            transferID: image.transferID,
            clipID: clipID,
            name: image.name,
            mime: image.mime,
            size: image.size,
            sha256: image.sha256
        )
    }

    public init?(representation: ClipRepresentation, clipID: ClipID) {
        switch representation {
        case .file(let file): self.init(file: file, clipID: clipID)
        case .image(let image): self.init(image: image, clipID: clipID)
        default: return nil
        }
    }

    public var startMessage: TransferStartMessage {
        TransferStartMessage(
            transferID: transferID,
            clipID: clipID,
            name: name,
            mime: mime,
            size: size,
            sha256: sha256
        )
    }
}
