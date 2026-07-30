import SwiftUI

@MainActor
struct DirectionChoiceButton: View {
    let choice: DirectionChoice
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.tight) {
                Image(systemName: choice.symbolName)
                    .font(.system(size: Theme.Size.directionSymbol, weight: .medium))
                    .frame(height: Theme.Size.directionSymbolRow)
                Text(choice.title)
                    .font(Theme.Typography.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(height: Theme.Size.directionLabelRow)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.small)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .fill(isSelected ? Theme.Palette.selection : Theme.Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .strokeBorder(Theme.Palette.selection.opacity(isSelected ? 0 : 0.25))
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(choice.title)
        .help(choice.detail)
    }
}
