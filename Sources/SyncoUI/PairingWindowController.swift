import AppKit
import SwiftUI
import SyncoCore
import SyncoSync

@MainActor
final class PairingWindowController {
    private let viewModel: AppViewModel
    private var window: NSWindow?
    private var presented: DeviceID?

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    func sync(with requests: [PairingRequestSnapshot]) {
        guard let request = requests.first else {
            dismiss()
            return
        }
        guard request.deviceID != presented else { return }
        present(request)
    }

    func dismiss() {
        window?.close()
        window = nil
        presented = nil
    }

    private func present(_ request: PairingRequestSnapshot) {
        dismiss()
        presented = request.deviceID
        let created = HostingWindowFactory.make(
            title: "Pair with \(request.displayName)",
            closable: false,
            content: PairingSheet(
                request: request,
                onApprove: { [viewModel] in viewModel.approvePairing(request.deviceID) },
                onReject: { [viewModel] in viewModel.rejectPairing(request.deviceID) }
            )
        )
        created.level = .floating
        window = created
        NSApp.activate()
        created.makeKeyAndOrderFront(nil)
    }
}
