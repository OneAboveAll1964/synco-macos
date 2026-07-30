import Foundation
import UniformTypeIdentifiers

public enum MIMEType {
    public static let octetStream = "application/octet-stream"
    public static let plainText = UTType.plainText.preferredMIMEType ?? "text/plain"
    public static let html = UTType.html.preferredMIMEType ?? "text/html"
    public static let rtf = UTType.rtf.preferredMIMEType ?? "text/rtf"
    public static let png = UTType.png.preferredMIMEType ?? "image/png"
    public static let tiff = UTType.tiff.preferredMIMEType ?? "image/tiff"

    public static func forFile(at url: URL) -> String {
        forPathExtension(url.pathExtension)
    }

    public static func forPathExtension(_ pathExtension: String) -> String {
        guard !pathExtension.isEmpty,
              let type = UTType(filenameExtension: pathExtension),
              let mime = type.preferredMIMEType
        else {
            return octetStream
        }
        return mime
    }

    public static func preferredFilenameExtension(for mime: String) -> String? {
        UTType(mimeType: mime)?.preferredFilenameExtension
    }

    public static func filename(base: String, mime: String) -> String {
        guard let suffix = preferredFilenameExtension(for: mime) else { return base }
        return "\(base).\(suffix)"
    }
}
