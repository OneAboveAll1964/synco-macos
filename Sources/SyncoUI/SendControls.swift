import AppKit
import SwiftUI

@MainActor
final class SendTextWindow {
    private var window: NSWindow?
    private let viewModel: AppViewModel

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }

    func present() {
        dismiss()
        let created = HostingWindowFactory.make(
            title: "Send text",
            closable: true,
            content: SendTextSheet(
                onSend: { [weak self] text in
                    self?.viewModel.sendText(text)
                    self?.dismiss()
                },
                onCancel: { [weak self] in self?.dismiss() }
            )
        )
        created.level = .floating
        window = created
        NSApp.activate()
        created.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        window?.close()
        window = nil
    }
}

struct SendTextSheet: View {
    let onSend: (String) -> Void
    let onCancel: () -> Void

    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            TextEditor(text: $draft)
                .font(Theme.Typography.body)
                .frame(width: 320, height: 120)
                .focused($focused)
            HStack {
                Text("Lands on your phone's clipboard.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: Theme.Spacing.medium)
                Button("Cancel", action: onCancel)
                Button("Send") { onSend(draft) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Theme.Spacing.large)
        .onAppear { focused = true }
    }
}

@MainActor
enum SendFilePicker {
    static func present(onPicked: @escaping ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "The selection is sent to your phone"
        panel.prompt = "Send"
        NSApp.activate()
        panel.begin { response in
            guard response == .OK, !panel.urls.isEmpty else { return }
            onPicked(panel.urls)
        }
    }
}
