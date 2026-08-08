import SwiftUI

public struct StatusPanelActions {
    let sendText: () -> Void
    let sendFiles: () -> Void
    let pairByQR: () -> Void
    let openSettings: () -> Void
    let quit: () -> Void

    public init(
        sendText: @escaping () -> Void,
        sendFiles: @escaping () -> Void,
        pairByQR: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        quit: @escaping () -> Void
    ) {
        self.sendText = sendText
        self.sendFiles = sendFiles
        self.pairByQR = pairByQR
        self.openSettings = openSettings
        self.quit = quit
    }
}

@MainActor
struct ActionRow: View {
    let actions: StatusPanelActions

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            action("Send text", icon: "character.cursor.ibeam", run: actions.sendText)
            action("Send files", icon: "doc.badge.arrow.up", run: actions.sendFiles)
            action("Pair by QR", icon: "qrcode", run: actions.pairByQR)
            Spacer(minLength: 0)
        }
    }

    private func action(_ title: String, icon: String, run: @escaping () -> Void) -> some View {
        Button(action: run) {
            Label(title, systemImage: icon)
        }
        .controlSize(.small)
        .help(title)
    }
}
