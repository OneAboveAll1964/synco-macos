import AppKit
import SwiftUI

@MainActor
public final class MenuBarController: NSObject {
    let viewModel: AppViewModel
    let statusItem: NSStatusItem
    let popover = NSPopover()
    let settingsWindow: SettingsWindowController

    private let pairingWindow: PairingWindowController
    private var iconLoop: ObservationLoop?
    private var pairingLoop: ObservationLoop?
    private var installedIcon: StatusItemIcon?

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        settingsWindow = SettingsWindowController(viewModel: viewModel)
        pairingWindow = PairingWindowController(viewModel: viewModel)
        super.init()
    }

    public func install() {
        configureButton()
        configurePopover()
        iconLoop = ObservationLoop { [weak self] in self?.refreshStatusItem() }
        pairingLoop = ObservationLoop { [weak self] in self?.refreshPairingWindow() }
    }

    public func teardown() {
        iconLoop?.cancel()
        pairingLoop?.cancel()
        iconLoop = nil
        pairingLoop = nil
        pairingWindow.dismiss()
        settingsWindow.close()
        popover.performClose(nil)
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    private func refreshStatusItem() {
        let summary = viewModel.summary
        let icon = StatusItemIcon.resolved(for: summary)
        statusItem.button?.toolTip = "Synco — \(summary.headline)"
        guard icon != installedIcon else { return }
        installedIcon = icon
        statusItem.button?.image = icon.image()
    }

    private func refreshPairingWindow() {
        pairingWindow.sync(with: viewModel.state.pendingPairings)
    }
}
