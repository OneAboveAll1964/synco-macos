import SwiftUI
import SyncoCore
import SyncoSync

@MainActor
struct PeerStatusLabel: View {
    let status: PeerLinkStatus

    var body: some View {
        HStack(spacing: Theme.Spacing.tight) {
            Circle()
                .fill(tint)
                .frame(width: Theme.Size.statusDot, height: Theme.Size.statusDot)
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var tint: Color {
        switch status {
        case .online: return Theme.Palette.online
        case .connecting, .retrying, .waitingForPeer: return Theme.Palette.engaged
        case .unpaired: return Theme.Palette.unpaired
        case .closed: return Theme.Palette.failure
        case .idle: return Theme.Palette.offline
        }
    }

    private var text: String {
        switch status {
        case .online: return "Connected"
        case .connecting: return "Connecting"
        case .waitingForPeer: return "Waiting for peer"
        case .retrying(let delay): return "Retrying in \(Int(delay.components.seconds))s"
        case .unpaired: return "Not paired"
        case .idle: return "Offline"
        case .closed(let reason): return "Disconnected — \(reason.rawValue)"
        }
    }
}
