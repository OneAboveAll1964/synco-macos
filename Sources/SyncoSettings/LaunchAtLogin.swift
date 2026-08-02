import AppKit
import Foundation
import SyncoCore

public enum LaunchAtLogin {
    public enum Status: String, Hashable, Sendable, CaseIterable {
        case enabled
        case disabled
        case requiresApproval
        case unavailable
    }

    public static let appBundleExtension = "app"

    public static var isSupported: Bool {
        Bundle.main.bundleIdentifier != nil
            && Bundle.main.bundleURL.pathExtension == appBundleExtension
    }

    public static var status: Status {
        guard isSupported else { return .unavailable }
        return LoginAgent.isInstalled() ? .enabled : .disabled
    }

    @discardableResult
    public static func apply(_ enabled: Bool) throws -> Status {
        guard isSupported, let executable = Bundle.main.executableURL else {
            SyncoLog.settings.notice("launch at login is unavailable outside an app bundle")
            return .unavailable
        }
        do {
            if enabled {
                try LoginAgent.install(executable: executable)
            } else {
                try LoginAgent.remove()
            }
        } catch {
            SyncoLog.settings.error(
                "launch at login update failed: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
        return status
    }

    public static func reconcile(wanted: Bool) -> Status {
        guard isSupported else { return .unavailable }
        let current = status
        guard wanted, current == .disabled else { return current }
        SyncoLog.settings.notice("re-registering Synco for launch at login after an update")
        return (try? apply(true)) ?? current
    }

    public static func openLoginItemsSettings() {
        guard let settings = URL(
            string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
        ) else {
            return
        }
        NSWorkspace.shared.open(settings)
    }
}

extension LaunchAtLogin.Status {
    public var isOn: Bool { self == .enabled || self == .requiresApproval }

    public func matches(_ wanted: Bool) -> Bool {
        wanted ? isOn : self == .disabled
    }
}
