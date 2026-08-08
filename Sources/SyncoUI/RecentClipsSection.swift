import AppKit
import SwiftUI
import SyncoSync

@MainActor
struct RecentClipsSection: View {
    let clips: [ClipHistoryEntry]

    @State private var copiedText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("RECENT CLIPS")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            ForEach(clips.prefix(5), id: \.self) { clip in
                Button {
                    copy(clip)
                } label: {
                    HStack(spacing: Theme.Spacing.small) {
                        Image(systemName: icon(for: clip))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 14)
                        Text(clip.text.replacingOccurrences(of: "\n", with: " "))
                            .font(Theme.Typography.body)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(copiedText == clip.text ? "Copied" : "Click to copy")
            }
        }
    }

    private func icon(for clip: ClipHistoryEntry) -> String {
        if copiedText == clip.text { return "checkmark" }
        return clip.isURL ? "link" : "doc.on.clipboard"
    }

    private func copy(_ clip: ClipHistoryEntry) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(clip.text, forType: .string)
        copiedText = clip.text
        Task {
            try? await Task.sleep(for: .seconds(2))
            if copiedText == clip.text { copiedText = nil }
        }
    }
}
