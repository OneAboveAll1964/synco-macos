import SwiftUI

@MainActor
struct TransferSettingsSection: View {
    let viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(title: "Transfers")
            Picker("Largest item to accept", selection: blobSizeBinding) {
                ForEach(BlobSizeOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            Text("Images and files above this size are refused instead of filling your disk.")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                Text("Received files")
                    .font(Theme.Typography.body)
                HStack(spacing: Theme.Spacing.small) {
                    Text(viewModel.receivedDirectory.path(percentEncoded: false))
                        .font(Theme.Typography.fingerprintCompact)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                    Spacer(minLength: 0)
                    Button("Reveal in Finder") { viewModel.revealReceivedFolder() }
                        .controlSize(.small)
                }
            }
        }
    }

    private var blobSizeBinding: Binding<BlobSizeOption> {
        Binding(
            get: { BlobSizeOption.nearest(viewModel.document.maxBlobBytes) },
            set: { viewModel.setMaxBlobBytes($0.rawValue) }
        )
    }
}
