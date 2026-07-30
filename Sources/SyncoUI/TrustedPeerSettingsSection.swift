import SwiftUI
import SyncoSettings

@MainActor
struct TrustedPeerSettingsSection: View {
    let viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(title: "Trusted devices")
            if viewModel.trustedPeers.isEmpty {
                Text("No devices are paired yet. Pair one from the Synco menu bar item.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.trustedPeers) { peer in
                    TrustedPeerSettingsRow(peer: peer) {
                        viewModel.forget(peer.deviceID)
                    }
                }
            }
        }
    }
}
