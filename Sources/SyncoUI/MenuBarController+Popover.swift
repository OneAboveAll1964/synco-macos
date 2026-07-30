import AppKit
import SwiftUI

extension MenuBarController {
    func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = StatusItemIcon.idle.image()
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.setAccessibilityLabel("Synco")
    }

    func configurePopover() {
        let controller = NSHostingController(
            rootView: StatusPanel(
                viewModel: viewModel,
                openSettings: { [weak self] in self?.openSettings() },
                quit: { NSApp.terminate(nil) }
            )
        )
        controller.sizingOptions = [.preferredContentSize]
        popover.contentViewController = controller
        popover.behavior = .transient
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    public func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func openSettings() {
        popover.performClose(nil)
        settingsWindow.show()
    }
}
