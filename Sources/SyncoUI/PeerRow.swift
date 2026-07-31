import SwiftUI
import SyncoSync

@MainActor
struct PeerRow: View {
    let peer: PeerSnapshot
    let viewModel: AppViewModel

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            if peer.isTrusted {
                Button(action: toggle) {
                    HStack(spacing: Theme.Spacing.small) {
                        identity
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: Theme.Size.disclosureChevron, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(peer.displayName)
                .accessibilityHint(isExpanded ? "Collapse settings" : "Expand settings")
                if isExpanded {
                    PeerPolicyDisclosure(peer: peer, viewModel: viewModel)
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

    private func toggle() {
        withAnimation(.easeInOut(duration: Theme.Timing.disclosure)) { isExpanded.toggle() }
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
