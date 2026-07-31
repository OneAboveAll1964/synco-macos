import SwiftUI

@MainActor
struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(title: "About")
            Text("Synco keeps this Mac and your Android phone sharing one clipboard over your local network. Nothing leaves your network and there is no account.")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Version \(AppVersion.string)")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            Link("github.com/OneAboveAll1964", destination: AppLinks.author)
                .font(Theme.Typography.caption)
        }
    }
}
