import AppKit
import Foundation
import SyncoTransfer

public struct PasteboardCapture: Hashable, Sendable {
    public let changeCount: Int
    public let fileURLs: [URL]
    public let png: Data?
    public let tiff: Data?
    public let rtf: Data?
    public let html: String?
    public let text: String?
    public let urlString: String?
    public let urlTitle: String?

    public init(
        changeCount: Int,
        fileURLs: [URL] = [],
        png: Data? = nil,
        tiff: Data? = nil,
        rtf: Data? = nil,
        html: String? = nil,
        text: String? = nil,
        urlString: String? = nil,
        urlTitle: String? = nil
    ) {
        self.changeCount = changeCount
        self.fileURLs = fileURLs
        self.png = png
        self.tiff = tiff
        self.rtf = rtf
        self.html = html
        self.text = text
        self.urlString = urlString
        self.urlTitle = urlTitle
    }

    @MainActor
    public static func systemPasteboard() -> PasteboardCapture {
        capture(of: NSPasteboard.general)
    }

    @MainActor
    public static func capture(of pasteboard: NSPasteboard) -> PasteboardCapture {
        let fileURLs = (pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL]) ?? []
        let advertised = pasteboard.string(forType: .URL)
        let plainURL = fileURLs.isEmpty ? advertised.flatMap(nonFileURL) : nil
        return PasteboardCapture(
            changeCount: pasteboard.changeCount,
            fileURLs: fileURLs,
            png: pasteboard.data(forType: .png),
            tiff: pasteboard.data(forType: .tiff),
            rtf: pasteboard.data(forType: .rtf),
            html: pasteboard.string(forType: .html),
            text: pasteboard.string(forType: .string),
            urlString: plainURL,
            urlTitle: plainURL == nil ? nil : pasteboard.string(forType: PasteboardTypeMapping.urlName)
        )
    }

    public var isEmpty: Bool {
        fileURLs.isEmpty && png == nil && tiff == nil && rtf == nil
            && html == nil && text == nil && urlString == nil
    }

    public var imageData: Data? { png ?? tiff }

    public var imageMIME: String { png != nil ? MIMEType.png : MIMEType.tiff }

    private static func nonFileURL(_ candidate: String) -> String? {
        candidate.lowercased().hasPrefix("file:") ? nil : candidate
    }
}
