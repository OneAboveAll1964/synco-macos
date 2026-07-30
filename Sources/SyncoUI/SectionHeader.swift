import SwiftUI

@MainActor
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(Theme.Typography.caption)
            .tracking(0.6)
            .foregroundStyle(.secondary)
    }
}
