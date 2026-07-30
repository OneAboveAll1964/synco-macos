import SwiftUI
import SyncoSync

@MainActor
struct ProblemBanner: View {
    let problem: SyncPermissionProblem

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Palette.engaged)
            VStack(alignment: .leading, spacing: 2) {
                Text(problem.title)
                    .font(Theme.Typography.title)
                Text(problem.detail)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Palette.warningBackground)
        )
    }
}
