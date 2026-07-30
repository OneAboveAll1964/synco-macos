import SwiftUI

@MainActor
struct DirectionControl: View {
    let selection: DirectionChoice
    let onSelect: (DirectionChoice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Sync direction")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: Theme.Spacing.tight) {
                ForEach(DirectionChoice.allCases) { choice in
                    DirectionChoiceButton(choice: choice, isSelected: choice == selection) {
                        onSelect(choice)
                    }
                }
            }
            Text(selection.detail)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
