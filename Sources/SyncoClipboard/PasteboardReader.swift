import Foundation
import SyncoCore
import SyncoTransfer

public struct PasteboardReader: Sendable {
    public static let imageName = "Clipboard Image"
    public static let richTextName = "Clipboard Rich Text"
    public static let markupName = "Clipboard Markup"
    public static let textName = "Clipboard Text"

    private let paths: TransferPaths
    private let threshold: InlineThreshold
    private let limit: BlobSizeLimit

    public init(
        paths: TransferPaths = .shared,
        threshold: InlineThreshold = .default,
        limit: BlobSizeLimit = .default
    ) {
        self.paths = paths
        self.threshold = threshold
        self.limit = limit
    }

    public func read(_ capture: PasteboardCapture) -> PasteboardSnapshot {
        var bundle = ClipRepresentationBundle()
        appendFiles(capture, into: &bundle)
        appendImage(capture, into: &bundle)
        appendRichText(capture, into: &bundle)
        appendMarkup(capture, into: &bundle)
        appendURL(capture, into: &bundle)
        appendText(capture, into: &bundle)
        return bundle.snapshot(changeCount: capture.changeCount)
    }

    private func appendFiles(_ capture: PasteboardCapture, into bundle: inout ClipRepresentationBundle) {
        for source in FileRepresentationSource.expand(capture.fileURLs) {
            guard let measurement = measure(source.url) else { continue }
            let transferID = TransferID()
            bundle.appendBlob(
                .file(ClipFileRepresentation(
                    mime: MIMEType.forFile(at: source.url),
                    name: source.name,
                    size: measurement.size,
                    sha256: measurement.sha256,
                    transferID: transferID,
                    rel: source.relativePath
                )),
                transferID: transferID,
                source: source.url
            )
        }
    }

    private func appendImage(_ capture: PasteboardCapture, into bundle: inout ClipRepresentationBundle) {
        guard capture.fileURLs.isEmpty, let data = capture.imageData else { return }
        let mime = capture.imageMIME
        let transferID = TransferID()
        guard let staged = stage(data, transferID: transferID, mime: mime) else { return }
        bundle.appendBlob(
            .image(ClipImageRepresentation(
                mime: mime,
                name: MIMEType.filename(base: Self.imageName, mime: mime),
                size: staged.measurement.size,
                sha256: staged.measurement.sha256,
                transferID: transferID
            )),
            transferID: transferID,
            source: staged.url
        )
    }

    private func appendRichText(_ capture: PasteboardCapture, into bundle: inout ClipRepresentationBundle) {
        guard capture.fileURLs.isEmpty else { return }
        guard let rtf = capture.rtf, !rtf.isEmpty else { return }
        guard threshold.allows(bytes: rtf) else {
            appendDemoted(rtf, base: Self.richTextName, mime: MIMEType.rtf, into: &bundle)
            return
        }
        bundle.append(.rtf(rtf))
    }

    private func appendMarkup(_ capture: PasteboardCapture, into bundle: inout ClipRepresentationBundle) {
        guard capture.fileURLs.isEmpty else { return }
        guard let html = capture.html, !html.isEmpty else { return }
        guard threshold.allows(text: html) else {
            appendDemoted(Data(html.utf8), base: Self.markupName, mime: MIMEType.html, into: &bundle)
            return
        }
        bundle.append(.html(html))
    }

    private func appendURL(_ capture: PasteboardCapture, into bundle: inout ClipRepresentationBundle) {
        guard capture.fileURLs.isEmpty else { return }
        guard let urlString = capture.urlString, !urlString.isEmpty,
              threshold.allows(text: urlString)
        else {
            return
        }
        bundle.append(.url(ClipURLRepresentation(url: urlString, title: capture.urlTitle)))
    }

    private func appendText(_ capture: PasteboardCapture, into bundle: inout ClipRepresentationBundle) {
        guard capture.fileURLs.isEmpty else { return }
        guard let text = capture.text, !text.isEmpty else { return }
        guard threshold.allows(text: text) else {
            appendDemoted(Data(text.utf8), base: Self.textName, mime: MIMEType.plainText, into: &bundle)
            return
        }
        bundle.append(.text(text))
    }

    private func appendDemoted(
        _ data: Data,
        base: String,
        mime: String,
        into bundle: inout ClipRepresentationBundle
    ) {
        let transferID = TransferID()
        guard let staged = stage(data, transferID: transferID, mime: mime) else { return }
        bundle.appendBlob(
            .file(ClipFileRepresentation(
                mime: mime,
                name: MIMEType.filename(base: base, mime: mime),
                size: staged.measurement.size,
                sha256: staged.measurement.sha256,
                transferID: transferID
            )),
            transferID: transferID,
            source: staged.url
        )
    }

    private func measure(_ url: URL) -> FileMeasurement? {
        do {
            let measurement = try FileMeasurement.measure(fileURL: url)
            return limit.allows(measurement.size) ? measurement : nil
        } catch {
            SyncoLog.clipboard.error("unreadable clipboard file: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func stage(_ data: Data, transferID: TransferID, mime: String) -> StagedPayload? {
        do {
            let staged = try StagedPayload.stage(data, transferID: transferID, mime: mime, paths: paths)
            return limit.allows(staged.measurement.size) ? staged : nil
        } catch {
            SyncoLog.clipboard.error("clipboard staging failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
