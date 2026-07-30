import SwiftUI
import SyncoCore
import SyncoSync

@MainActor
struct StatusPanelHeader: View {
    let identity: LocalIdentitySnapshot?
    let summary: ConnectionSummary

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text(identity?.displayName ?? "This Mac")
                    .font(Theme.Typography.heading)
                Text(summary.headline)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                if let fingerprint = identity?.fingerprint {
                    Text(fingerprint.grouped)
                        .font(Theme.Typography.fingerprintCompact)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .help("Compare this fingerprint when pairing a new device.")
                }
            }
            Spacer(minLength: 0)
            Image(systemName: StatusItemIcon.resolved(for: summary).symbolName)
                .font(.system(size: Theme.Size.directionSymbol))
                .foregroundStyle(.secondary)
        }
    }
}
