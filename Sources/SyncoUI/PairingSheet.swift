import SwiftUI
import SyncoSync

@MainActor
public struct PairingSheet: View {
    let request: PairingRequestSnapshot
    let onApprove: () -> Void
    let onReject: () -> Void

    public init(
        request: PairingRequestSnapshot,
        onApprove: @escaping () -> Void,
        onReject: @escaping () -> Void
    ) {
        self.request = request
        self.onApprove = onApprove
        self.onReject = onReject
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack(spacing: Theme.Spacing.small) {
                PlatformGlyph(platform: request.platform)
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.displayName)
                        .font(Theme.Typography.heading)
                    Text("wants to sync clipboards with this Mac")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Divider()
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Text("Check that these four groups match exactly what \(request.displayName) is showing.")
                    .font(Theme.Typography.body)
                    .fixedSize(horizontal: false, vertical: true)
                FingerprintDisplay(fingerprint: request.fingerprint)
                Text("If they differ, do not pair — something else is answering on this network.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Theme.Spacing.small) {
                Spacer(minLength: 0)
                Button("Don't Pair", role: .cancel, action: onReject)
                    .keyboardShortcut(.cancelAction)
                Button("Pair", action: onApprove)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.Spacing.section)
        .frame(width: Theme.Size.pairingWidth)
    }
}
