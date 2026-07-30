import SwiftUI
import SyncoCore

@MainActor
struct FingerprintDisplay: View {
    let fingerprint: Fingerprint

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                Text(group)
                    .font(Theme.Typography.fingerprint)
                    .kerning(2)
                    .padding(.horizontal, Theme.Spacing.small)
                    .padding(.vertical, Theme.Spacing.tight)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.control)
                            .fill(Theme.Palette.card)
                    )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spelled)
    }

    private var groups: [String] {
        fingerprint.grouped
            .split(separator: Character(SyncoConstants.Identity.fingerprintGroupSeparator))
            .map(String.init)
    }

    private var spelled: String {
        fingerprint.compact.map(String.init).joined(separator: " ")
    }
}
