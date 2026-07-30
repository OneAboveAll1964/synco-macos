import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let viewModel: AppViewModel
    private var window: NSWindow?

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    func show() {
        let window = existingOrCreated()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
        window = nil
    }

    private func existingOrCreated() -> NSWindow {
        if let window { return window }
        let created = HostingWindowFactory.make(
            title: "Synco Settings",
            closable: true,
            content: SettingsScene(viewModel: viewModel)
        )
        window = created
        return created
    }
}
