import SwiftUI
import SyncoCore

@MainActor
struct PlatformGlyph: View {
    let platform: DevicePlatform

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: Theme.Size.glyph))
            .foregroundStyle(.secondary)
            .accessibilityLabel(platform.displayName)
            .frame(width: Theme.Size.glyph + Theme.Spacing.small)
    }

    private var symbolName: String {
        switch platform {
        case .macOS: return "laptopcomputer"
        case .android: return "iphone"
        }
    }
}
