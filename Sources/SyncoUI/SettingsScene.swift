import SwiftUI

@MainActor
public struct SettingsScene: View {
    let viewModel: AppViewModel

    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                GeneralSettingsSection(viewModel: viewModel)
                Divider()
                TransferSettingsSection(viewModel: viewModel)
                Divider()
                TrustedPeerSettingsSection(viewModel: viewModel)
            }
            .padding(Theme.Spacing.section)
            .frame(width: Theme.Size.settingsWidth, alignment: .leading)
        }
        .frame(width: Theme.Size.settingsWidth, height: Theme.Size.settingsHeight)
    }
}
