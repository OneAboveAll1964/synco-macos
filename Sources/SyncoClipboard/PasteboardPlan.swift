import AppKit
import Foundation
import SyncoCore

struct PasteboardAttachment: Sendable {
    let url: URL
    let imageType: NSPasteboard.PasteboardType?
    let imageBytes: Data?
}

struct PasteboardPlan {
    private(set) var inline: [(NSPasteboard.PasteboardType, PasteboardWriter.Payload)] = []
    private(set) var attachments: [PasteboardAttachment] = []

    var isEmpty: Bool { inline.isEmpty && attachments.isEmpty }

    init(_ representations: [ClipRepresentation], receivedFiles: [TransferID: URL]) {
        for representation in representations {
            switch representation {
            case .rtf(let bytes):
                inline.append((.rtf, .data(bytes)))
            case .html(let markup):
                inline.append((.html, .string(markup)))
            case .url(let link):
                inline.append((.URL, .string(link.url)))
                if let title = link.title {
                    inline.append((PasteboardTypeMapping.urlName, .string(title)))
                }
            case .text(let text):
                inline.append((.string, .string(text)))
            case .image(let image):
                guard let source = receivedFiles[image.transferID] else { continue }
                attachments.append(
                    PasteboardAttachment(
                        url: source,
                        imageType: PasteboardTypeMapping.imageType(forMIME: image.mime),
                        imageBytes: try? Data(contentsOf: source, options: .mappedIfSafe)
                    )
                )
            case .file(let file):
                guard let source = receivedFiles[file.transferID] else { continue }
                attachments.append(
                    PasteboardAttachment(url: source, imageType: nil, imageBytes: nil)
                )
            }
        }
    }
}
