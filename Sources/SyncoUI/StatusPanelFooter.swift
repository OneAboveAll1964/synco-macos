import SwiftUI

@MainActor
struct StatusPanelFooter: View {
    let openSettings: () -> Void
    let quit: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Button {
                openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .controlSize(.small)
            Spacer(minLength: 0)
            Button {
                quit()
            } label: {
                Label("Quit", systemImage: "power")
            }
            .controlSize(.small)
        }
    }
}
