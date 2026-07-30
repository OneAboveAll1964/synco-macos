import AppKit
import Foundation
import UniformTypeIdentifiers

public enum PasteboardTypeMapping {
    public static let urlName = NSPasteboard.PasteboardType(rawValue: "public.url-name")

    public static func type(forMIME mime: String) -> NSPasteboard.PasteboardType? {
        guard let type = UTType(mimeType: mime) else { return nil }
        return NSPasteboard.PasteboardType(type.identifier)
    }

    public static func imageType(forMIME mime: String) -> NSPasteboard.PasteboardType {
        type(forMIME: mime) ?? .png
    }
}
