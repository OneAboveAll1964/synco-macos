import AppKit
import Foundation

@MainActor
enum FinderReveal {
    static func show(_ url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
