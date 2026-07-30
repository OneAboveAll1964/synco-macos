import Foundation

public enum TransferFileName {
    public static let fallback = "Untitled"
    public static let maxCharacters = 200
    public static let maxCollisionAttempts = 4096

    private static let illegal = CharacterSet(charactersIn: "/\\:\u{0}")

    public static func sanitized(_ proposal: String) -> String {
        let collapsed = proposal
            .components(separatedBy: illegal)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !collapsed.isEmpty, collapsed != ".", collapsed != ".." else { return fallback }
        return String(collapsed.prefix(maxCharacters))
    }

    public static func sanitizedComponents(_ relativePath: String) -> [String] {
        relativePath.split(separator: "/").map { sanitized(String($0)) }
    }

    public static func availableURL(in directory: URL, name: String) -> URL {
        let safe = sanitized(name)
        let first = directory.appending(path: safe, directoryHint: .notDirectory)
        guard exists(first) else { return first }
        let base = (safe as NSString).deletingPathExtension
        let suffix = (safe as NSString).pathExtension
        for attempt in 2...maxCollisionAttempts {
            let candidate = directory.appending(
                path: numbered(base: base, suffix: suffix, index: attempt),
                directoryHint: .notDirectory
            )
            if !exists(candidate) { return candidate }
        }
        return directory.appending(
            path: numbered(base: "\(base)-\(UUID().uuidString)", suffix: suffix, index: nil),
            directoryHint: .notDirectory
        )
    }

    private static func numbered(base: String, suffix: String, index: Int?) -> String {
        let stem = index.map { "\(base) \($0)" } ?? base
        return suffix.isEmpty ? stem : "\(stem).\(suffix)"
    }

    private static func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }
}
