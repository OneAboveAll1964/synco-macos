import SwiftUI
import SyncoSettings

@MainActor
struct GeneralSettingsSection: View {
    let viewModel: AppViewModel

    @State private var draftName = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(title: "General")
            HStack(spacing: Theme.Spacing.small) {
                Text("Name on this network")
                    .font(Theme.Typography.body)
                    .frame(width: Theme.Size.settingsLabelWidth, alignment: .leading)
                TextField("", text: $draftName)
                    .focused($isNameFocused)
                    .onSubmit { viewModel.setDisplayName(draftName) }
            }
            Text("Your other devices show this name when they find this Mac.")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            Toggle("Open Synco at login", isOn: launchBinding)
                .disabled(viewModel.launchAtLoginStatus == .unavailable)
            if let note = launchNote {
                HStack(spacing: Theme.Spacing.small) {
                    Text(note)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if viewModel.launchAtLoginStatus == .requiresApproval {
                        Button("Open Login Items") { viewModel.openLoginItemsSettings() }
                            .controlSize(.small)
                    }
                }
            }
        }
        .onAppear {
            draftName = viewModel.document.displayName
            viewModel.refreshLaunchAtLogin()
        }
        .onChange(of: viewModel.document.displayName) { _, updated in
            draftName = updated
        }
        .onChange(of: isNameFocused) { _, focused in
            guard !focused else { return }
            viewModel.setDisplayName(draftName)
        }
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { viewModel.launchAtLoginStatus.isOn },
            set: { viewModel.setLaunchAtLogin($0) }
        )
    }

    private var launchNote: String? {
        switch viewModel.launchAtLoginStatus {
        case .unavailable:
            return "Launching at login needs Synco to run from Synco.app, not from a loose binary."
        case .requiresApproval:
            return "macOS is waiting for you to allow Synco in Login Items."
        case .enabled, .disabled:
            return nil
        }
    }
}
