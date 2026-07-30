import Foundation
import SyncoSettings

public struct InstanceLockLocation: Hashable, Sendable {
    public static let fileName = "instance.lock"

    public static let `default` = InstanceLockLocation()

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public init(settings: SettingsLocation = .default) {
        fileURL = settings.directoryURL
            .appending(path: Self.fileName, directoryHint: .notDirectory)
    }

    public var directoryURL: URL {
        fileURL.deletingLastPathComponent()
    }
}
