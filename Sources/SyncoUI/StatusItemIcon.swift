import AppKit

enum StatusItemIcon: String, Hashable, CaseIterable {
    case idle
    case connected
    case syncing
    case paused
    case attention

    static func resolved(for summary: ConnectionSummary) -> StatusItemIcon {
        if summary.hasProblem || summary.hasPendingPairing { return .attention }
        if summary.isPaused { return .paused }
        if summary.activeTransferCount > 0 { return .syncing }
        if summary.onlineCount > 0 { return .connected }
        return .idle
    }

    var symbolName: String {
        switch self {
        case .idle: return "square.on.square.dashed"
        case .connected: return "square.on.square"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .paused: return "pause.circle"
        case .attention: return "exclamationmark.triangle.fill"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .idle: return "Synco, no devices connected"
        case .connected: return "Synco, connected"
        case .syncing: return "Synco, transferring"
        case .paused: return "Synco, paused"
        case .attention: return "Synco, needs attention"
        }
    }

    func image() -> NSImage? {
        let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: accessibilityDescription
        )
        image?.isTemplate = true
        return image
    }
}
