import Foundation
import SyncoCore

public struct SettingsLocation: Hashable, Sendable {
    public static let fileName = "settings.json"

    public static let `default` = SettingsLocation()

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public init(containerName: String = SyncoLog.subsystem) {
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? home.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        fileURL = support
            .appending(path: containerName, directoryHint: .isDirectory)
            .appending(path: Self.fileName, directoryHint: .notDirectory)
    }

    public var directoryURL: URL {
        fileURL.deletingLastPathComponent()
    }
}
