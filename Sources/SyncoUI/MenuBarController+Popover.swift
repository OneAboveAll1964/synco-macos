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
                actions: StatusPanelActions(
                    sendText: { [weak self] in self?.openSendText() },
                    sendFiles: { [weak self] in self?.openSendFiles() },
                    pairByQR: { [weak self] in self?.openQRPairing() },
                    openSettings: { [weak self] in self?.openSettings() },
                    quit: { NSApp.terminate(nil) }
                )
            )
        )
        controller.sizingOptions = [.preferredContentSize]
        popover.contentViewController = controller
        popover.behavior = .transient
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    public func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        startDismissMonitor()
    }

    public func closePopover() {
        stopDismissMonitor()
        popover.performClose(nil)
    }

    func openSendText() {
        closePopover()
        sendTextWindow.present()
    }

    func openSendFiles() {
        closePopover()
        SendFilePicker.present { [viewModel] urls in
            viewModel.sendFiles(urls)
        }
    }

    func openQRPairing() {
        closePopover()
        viewModel.beginQRPairing { [weak self] code in
            self?.qrWindow.present(code)
        }
    }

    func openSettings() {
        closePopover()
        settingsWindow.show()
    }

    private func startDismissMonitor() {
        guard dismissMonitor == nil else { return }
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.closePopover() }
        }
    }

    private func stopDismissMonitor() {
        guard let monitor = dismissMonitor else { return }
        NSEvent.removeMonitor(monitor)
        dismissMonitor = nil
    }
}
