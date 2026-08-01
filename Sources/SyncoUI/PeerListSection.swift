import SwiftUI
import SyncoSync

@MainActor
struct PeerListSection: View {
    let viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            if viewModel.state.peers.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        group("Paired", peers: viewModel.pairedPeers)
                        group("Nearby", peers: viewModel.nearbyPeers)
                    }
                }
                .scrollIndicators(.never)
                .frame(maxHeight: Theme.Size.peerListMaxHeight)
            }
        }
    }

    @ViewBuilder
    private func group(_ title: String, peers: [PeerSnapshot]) -> some View {
        if !peers.isEmpty {
            SectionHeader(title: title)
            ForEach(peers) { peer in
                PeerRow(peer: peer, viewModel: viewModel)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text("No devices found yet")
                .font(Theme.Typography.title)
            Text("Open Synco on your phone while both devices are on the same Wi-Fi network.")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Palette.card)
        )
    }
}
