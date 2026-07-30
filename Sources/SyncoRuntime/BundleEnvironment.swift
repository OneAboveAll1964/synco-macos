import Foundation
import SyncoSettings

public struct BundleEnvironment: Equatable, Sendable {
    public let bundleIdentifier: String?
    public let pathExtension: String

    public init(bundleIdentifier: String?, pathExtension: String) {
        self.bundleIdentifier = bundleIdentifier
        self.pathExtension = pathExtension
    }

    public static var current: BundleEnvironment {
        BundleEnvironment(
            bundleIdentifier: Bundle.main.bundleIdentifier,
            pathExtension: Bundle.main.bundleURL.pathExtension
        )
    }

    public var isBundled: Bool {
        bundleIdentifier != nil && pathExtension == LaunchAtLogin.appBundleExtension
    }

    public var startupNotice: String? {
        guard !isBundled else { return nil }
        return """
        running outside Synco.app: discovery, pairing, and clipboard sync still run for \
        development, but macOS withholds local network permission and launch at login from \
        an unbundled binary, so peers may never appear — run Scripts/package-app.sh and \
        open dist/Synco.app for a working install
        """
    }
}
