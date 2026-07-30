import SwiftUI
import SyncoTransfer

@MainActor
struct TransferRow: View {
    let transfer: TransferProgress
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Image(systemName: directionSymbol)
                .font(.system(size: Theme.Size.glyph - 2))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(transfer.name)
                    .font(Theme.Typography.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                ProgressView(value: transfer.fraction)
                    .progressViewStyle(.linear)
                Text(ByteSizeText.progress(
                    transferred: transfer.transferredBytes,
                    total: transfer.totalBytes
                ))
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            }
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Cancel this transfer")
            .accessibilityLabel("Cancel transfer of \(transfer.name)")
        }
    }

    private var directionSymbol: String {
        transfer.direction == .incoming ? "arrow.down.circle" : "arrow.up.circle"
    }
}
