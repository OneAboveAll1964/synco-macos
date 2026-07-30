import SwiftUI
import SyncoCore
import SyncoSync

@MainActor
struct TypeToggleRow: View {
    let title: String
    let flags: ClipTypeFlags
    let isEnabled: Bool
    let onChange: (ClipTypeCategory, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: Theme.Spacing.medium) {
                ForEach(ClipTypeCategory.allCases) { category in
                    Toggle(isOn: binding(for: category)) {
                        Text(category.title).font(Theme.Typography.caption)
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                }
                Spacer(minLength: 0)
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private func binding(for category: ClipTypeCategory) -> Binding<Bool> {
        Binding(
            get: { category.isEnabled(in: flags) },
            set: { onChange(category, $0) }
        )
    }
}
