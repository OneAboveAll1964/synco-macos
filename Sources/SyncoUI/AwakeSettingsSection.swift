import SwiftUI

@MainActor
struct AwakeSettingsSection: View {
    let viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(title: "Stay awake")
            Toggle("Keep this Mac awake", isOn: awakeBinding)
            Text("The display stays on and the Mac never sleeps on its own, so you can reach it at any time.")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Toggle("Stay awake with the lid closed", isOn: lidBinding)
                .disabled(!viewModel.document.keepAwake)
            Text("Turning this on asks for your administrator password once, because it changes a system power setting.")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var awakeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.document.keepAwake },
            set: { viewModel.setKeepAwake($0) }
        )
    }

    private var lidBinding: Binding<Bool> {
        Binding(
            get: { viewModel.document.keepAwakeWithLidClosed },
            set: { viewModel.setKeepAwakeWithLidClosed($0) }
        )
    }
}
