import AppKit
import Foundation
import SyncoCore

public struct PasteboardWriter: Sendable {
    enum Payload {
        case data(Data)
        case string(String)
    }

    public init() {}

    @MainActor
    @discardableResult
    public func applyToSystemPasteboard(
        _ representations: [ClipRepresentation],
        receivedFiles: [TransferID: URL]
    ) -> Int {
        apply(representations, receivedFiles: receivedFiles, to: NSPasteboard.general)
    }

    @MainActor
    @discardableResult
    public func apply(
        _ representations: [ClipRepresentation],
        receivedFiles: [TransferID: URL],
        to pasteboard: NSPasteboard
    ) -> Int {
        var payloads: [(NSPasteboard.PasteboardType, Payload)] = []
        var fileURLs: [URL] = []
        for representation in representations {
            switch representation {
            case .rtf(let bytes):
                payloads.append((.rtf, .data(bytes)))
            case .html(let markup):
                payloads.append((.html, .string(markup)))
            case .url(let link):
                payloads.append((.URL, .string(link.url)))
                if let title = link.title {
                    payloads.append((PasteboardTypeMapping.urlName, .string(title)))
                }
            case .text(let text):
                payloads.append((.string, .string(text)))
            case .image(let image):
                guard let source = receivedFiles[image.transferID],
                      let bytes = try? Data(contentsOf: source, options: .mappedIfSafe)
                else {
                    continue
                }
                payloads.append((PasteboardTypeMapping.imageType(forMIME: image.mime), .data(bytes)))
            case .file(let file):
                guard let source = receivedFiles[file.transferID] else { continue }
                fileURLs.append(source)
            }
        }
        return write(payloads: payloads, fileURLs: fileURLs, to: pasteboard)
    }

    @MainActor
    private func write(
        payloads: [(NSPasteboard.PasteboardType, Payload)],
        fileURLs: [URL],
        to pasteboard: NSPasteboard
    ) -> Int {
        guard !payloads.isEmpty || !fileURLs.isEmpty else { return pasteboard.changeCount }
        var items: [NSPasteboardItem] = []
        let primary = NSPasteboardItem()
        if let first = fileURLs.first {
            primary.setString(first.absoluteString, forType: .fileURL)
        }
        for (type, payload) in payloads {
            payload.write(to: primary, type: type)
        }
        items.append(primary)
        for source in fileURLs.dropFirst() {
            let item = NSPasteboardItem()
            item.setString(source.absoluteString, forType: .fileURL)
            items.append(item)
        }
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
        return pasteboard.changeCount
    }
}

extension PasteboardWriter.Payload {
    @MainActor
    func write(to item: NSPasteboardItem, type: NSPasteboard.PasteboardType) {
        switch self {
        case .data(let bytes): item.setData(bytes, forType: type)
        case .string(let text): item.setString(text, forType: type)
        }
    }
}
