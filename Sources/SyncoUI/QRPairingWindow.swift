import AppKit
import CoreImage.CIFilterBuiltins
import SwiftUI
import SyncoSync

@MainActor
final class QRPairingWindow {
    private var window: NSWindow?
    private let viewModel: AppViewModel

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    func present(_ code: QRPairingCode) {
        dismiss()
        let created = HostingWindowFactory.make(
            title: "Pair by QR code",
            closable: true,
            content: QRPairingSheet(code: code) { [weak self] in self?.dismiss() }
        )
        created.level = .floating
        window = created
        NSApp.activate()
        created.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        guard window != nil else { return }
        window?.close()
        window = nil
        viewModel.endQRPairing()
    }
}

struct QRPairingSheet: View {
    let code: QRPairingCode
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            if let image = QRCodeImage.render(code.payload) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 260, height: 260)
                    .accessibilityLabel("QR pairing code")
            }
            Text("On your phone, open Synco → Settings → Pair with a QR code, and point the camera here.")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .frame(width: 280)
                .fixedSize(horizontal: false, vertical: true)
            Text("The code stops working the moment one phone uses it.")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            Button("Done", action: onDone)
                .keyboardShortcut(.defaultAction)
        }
        .padding(Theme.Spacing.large)
    }
}

enum QRCodeImage {
    static func render(_ payload: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: scaled.extent.width, height: scaled.extent.height))
    }
}
