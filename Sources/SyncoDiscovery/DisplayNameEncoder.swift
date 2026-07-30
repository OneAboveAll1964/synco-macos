import Foundation
import SyncoCore

public enum DisplayNameEncoder {
    public static func truncated(
        _ name: String,
        maxBytes: Int = SyncoConstants.Discovery.displayNameMaxBytes
    ) -> String {
        guard name.utf8.count > maxBytes else { return name }
        var truncated = String.UnicodeScalarView()
        var used = 0
        for scalar in name.unicodeScalars {
            let width = String(scalar).utf8.count
            guard used + width <= maxBytes else { break }
            truncated.append(scalar)
            used += width
        }
        return String(truncated)
    }
}
