import Foundation
import ServiceManagement
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
        return mapped(SMAppService.mainApp.status)
    }

    @discardableResult
    public static func apply(_ enabled: Bool) throws -> Status {
        guard isSupported else {
            SyncoLog.settings.notice("launch at login is unavailable outside an app bundle")
            return .unavailable
        }
        let service = SMAppService.mainApp
        do {
            if enabled {
                guard service.status != .enabled else { return .enabled }
                try service.register()
            } else {
                guard service.status != .notRegistered else { return .disabled }
                try service.unregister()
            }
        } catch {
            SyncoLog.settings.error("launch at login update failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
        return mapped(service.status)
    }

    public static func reconcile(wanted: Bool) -> Status {
        guard isSupported else { return .unavailable }
        let current = status
        guard wanted else { return current }
        guard current == .disabled else { return current }
        SyncoLog.settings.notice("re-registering Synco for launch at login after an update")
        return (try? apply(true)) ?? current
    }

    public static func openLoginItemsSettings() {
        guard isSupported else { return }
        SMAppService.openSystemSettingsLoginItems()
    }

    private static func mapped(_ status: SMAppService.Status) -> Status {
        switch status {
        case .enabled: return .enabled
        case .notRegistered: return .disabled
        case .requiresApproval: return .requiresApproval
        case .notFound: return .unavailable
        @unknown default: return .unavailable
        }
    }
}

extension LaunchAtLogin.Status {
    public var isOn: Bool { self == .enabled || self == .requiresApproval }

    public func matches(_ wanted: Bool) -> Bool {
        wanted ? isOn : self == .disabled
    }
}
