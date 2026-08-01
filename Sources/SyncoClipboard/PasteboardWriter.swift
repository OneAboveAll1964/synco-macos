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
        write(PasteboardPlan(representations, receivedFiles: receivedFiles), to: pasteboard)
    }

    @MainActor
    private func write(_ plan: PasteboardPlan, to pasteboard: NSPasteboard) -> Int {
        guard !plan.isEmpty else { return pasteboard.changeCount }
        let carriesFileURLs = plan.attachments.count > 1
        var items: [NSPasteboardItem] = []
        let primary = NSPasteboardItem()
        if let first = plan.attachments.first {
            attach(first, to: primary, withFileURL: carriesFileURLs)
        }
        for (type, payload) in plan.inline {
            payload.write(to: primary, type: type)
        }
        items.append(primary)
        for attachment in plan.attachments.dropFirst() {
            let item = NSPasteboardItem()
            attach(attachment, to: item, withFileURL: true)
            items.append(item)
        }
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
        return pasteboard.changeCount
    }

    @MainActor
    private func attach(
        _ attachment: PasteboardAttachment,
        to item: NSPasteboardItem,
        withFileURL: Bool
    ) {
        if withFileURL || attachment.imageType == nil {
            item.setString(attachment.url.absoluteString, forType: .fileURL)
        }
        if let type = attachment.imageType, let bytes = attachment.imageBytes {
            item.setData(bytes, forType: type)
        }
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
