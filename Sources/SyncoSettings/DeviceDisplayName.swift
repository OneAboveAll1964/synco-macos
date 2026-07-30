import Foundation
import SyncoCore

public enum DeviceDisplayName {
    public static let fallback = "Mac"

    public static var systemDefault: String {
        truncated(Host.current().localizedName ?? ProcessInfo.processInfo.hostName)
    }

    public static func truncated(_ proposal: String) -> String {
        let trimmed = proposal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        let limit = SyncoConstants.Discovery.displayNameMaxBytes
        guard trimmed.utf8.count > limit else { return trimmed }
        var result = ""
        var bytes = 0
        for character in trimmed {
            let width = String(character).utf8.count
            guard bytes + width <= limit else { break }
            result.append(character)
            bytes += width
        }
        return result.isEmpty ? fallback : result
    }
}
