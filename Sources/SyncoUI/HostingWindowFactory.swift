import AppKit
import SwiftUI

@MainActor
enum HostingWindowFactory {
    static func make(title: String, closable: Bool, content: some View) -> NSWindow {
        let controller = NSHostingController(rootView: content)
        controller.sizingOptions = [.preferredContentSize]
        let window = NSWindow(contentViewController: controller)
        var style: NSWindow.StyleMask = [.titled]
        if closable {
            style.insert(.closable)
        }
        window.styleMask = style
        window.title = title
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.center()
        return window
    }
}
