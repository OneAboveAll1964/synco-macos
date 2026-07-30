import AppKit
import SwiftUI

enum Theme {
    enum Spacing {
        static let tight: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let section: CGFloat = 20
    }

    enum Radius {
        static let control: CGFloat = 7
        static let card: CGFloat = 10
    }

    enum Size {
        static let popoverWidth: CGFloat = 412
        static let peerListMaxHeight: CGFloat = 260
        static let transferListMaxHeight: CGFloat = 140
        static let settingsWidth: CGFloat = 520
        static let settingsHeight: CGFloat = 560
        static let settingsLabelWidth: CGFloat = 156
        static let pairingWidth: CGFloat = 400
        static let glyph: CGFloat = 15
        static let statusDot: CGFloat = 7
        static let directionSymbol: CGFloat = 17
        static let directionSymbolRow: CGFloat = 20
        static let directionLabelRow: CGFloat = 14
    }

    enum Palette {
        static let online = Color.green
        static let engaged = Color.orange
        static let offline = Color.secondary
        static let failure = Color.red
        static let unpaired = Color.accentColor
        static let card = Color(nsColor: .controlBackgroundColor)
        static let selection = Color.accentColor
        static let warningBackground = Color.orange.opacity(0.14)
    }

    enum Typography {
        static let heading = Font.system(size: 13, weight: .semibold)
        static let title = Font.system(size: 12, weight: .medium)
        static let body = Font.system(size: 12)
        static let caption = Font.system(size: 11)
        static let fingerprint = Font.system(size: 17, weight: .semibold, design: .monospaced)
        static let fingerprintCompact = Font.system(size: 11, design: .monospaced)
    }
}
