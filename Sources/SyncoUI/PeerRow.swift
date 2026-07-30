import SwiftUI
import SyncoSync

@MainActor
struct PeerRow: View {
    let peer: PeerSnapshot
    let viewModel: AppViewModel

    @State private var isExpanded = false

    var body: some View {
        Group {
            if peer.isTrusted {
                DisclosureGroup(isExpanded: $isExpanded) {
                    PeerPolicyDisclosure(peer: peer, viewModel: viewModel)
                        .padding(.top, Theme.Spacing.small)
                } label: {
                    identity
                }
            } else {
                HStack(spacing: Theme.Spacing.small) {
                    identity
                    Button("Pair") { viewModel.beginPairing(with: peer.deviceID) }
                        .controlSize(.small)
                }
            }
        }
        .padding(Theme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Palette.card)
        )
    }

    private var identity: some View {
        HStack(spacing: Theme.Spacing.small) {
            PlatformGlyph(platform: peer.platform)
            VStack(alignment: .leading, spacing: 2) {
                Text(peer.displayName)
                    .font(Theme.Typography.title)
                    .lineLimit(1)
                PeerStatusLabel(status: peer.status)
            }
            Spacer(minLength: 0)
        }
    }
}
