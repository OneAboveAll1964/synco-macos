import Foundation

public enum AdbLocator {

    public static let searchPaths: [String] = [
        "/opt/homebrew/bin/adb",
        "/usr/local/bin/adb",
        "/usr/bin/adb",
        NSHomeDirectory() + "/Library/Android/sdk/platform-tools/adb",
        NSHomeDirectory() + "/Android/Sdk/platform-tools/adb",
    ]

    public static func locate(
        using fileManager: FileManager = .default,
        candidates: [String] = searchPaths
    ) -> URL? {
        for path in candidates where fileManager.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
}
