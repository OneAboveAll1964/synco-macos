import SwiftUI
import SyncoCore
import SyncoSettings

@MainActor
struct TrustedPeerSettingsRow: View {
    let peer: TrustedPeerRecord
    let onForget: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            PlatformGlyph(platform: peer.platform)
            VStack(alignment: .leading, spacing: 2) {
                Text(peer.displayName)
                    .font(Theme.Typography.title)
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button("Forget", role: .destructive, action: onForget)
                .controlSize(.small)
        }
        .padding(Theme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Palette.card)
        )
    }

    private var subtitle: String {
        guard let fingerprint = peer.fingerprint else {
            return "Identity key no longer matches — forget and pair again"
        }
        let paired = peer.firstPairedAt.formatted(date: .abbreviated, time: .shortened)
        return "\(fingerprint.grouped) · paired \(paired)"
    }
}
