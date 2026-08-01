import Foundation
import SyncoCore

enum PeerPlatformRule {

    static func pairs(_ local: DevicePlatform, _ peer: DevicePlatform) -> Bool {
        local != peer
    }
}
