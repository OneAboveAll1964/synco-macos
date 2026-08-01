import SwiftUI
import SyncoSync

@MainActor
struct ShizukuSettingsSection: View {
    let viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(title: "Android clipboard access")
            Toggle("Let a paired phone start Shizuku over adb", isOn: allowBinding)
                .disabled(!hasAdb)
            Text(note)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var hasAdb: Bool { AdbLocator.locate() != nil }

    private var note: String {
        guard hasAdb else {
            return """
            Install the Android platform tools to use this. Synco looks for adb in Homebrew's \
            bin folder and in the Android SDK.
            """
        }
        return """
        Shizuku has to be restarted after every phone reboot. With this on, the phone can ask \
        this Mac to run that one command over adb while it is plugged in. Only devices you have \
        already paired can ask, and nothing else can be run.
        """
    }

    private var allowBinding: Binding<Bool> {
        Binding(
            get: { viewModel.document.allowsAdbShizukuStart },
            set: { viewModel.setAllowsAdbShizukuStart($0) }
        )
    }
}
