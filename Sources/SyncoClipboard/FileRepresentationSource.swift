import Foundation

public struct FileRepresentationSource: Hashable, Sendable {
    public let url: URL
    public let name: String
    public let relativePath: String?

    public init(url: URL, name: String, relativePath: String? = nil) {
        self.url = url
        self.name = name
        self.relativePath = relativePath
    }

    public static func expand(_ urls: [URL]) -> [FileRepresentationSource] {
        urls.flatMap { expand($0) }
    }

    public static func expand(_ url: URL) -> [FileRepresentationSource] {
        guard isDirectory(url) else {
            return [FileRepresentationSource(url: url, name: url.lastPathComponent)]
        }
        let root = url.lastPathComponent
        let options: FileManager.DirectoryEnumerationOptions = [
            .skipsHiddenFiles, .skipsPackageDescendants,
        ]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: options
        ) else {
            return []
        }
        var sources: [FileRepresentationSource] = []
        for case let child as URL in enumerator {
            guard isRegularFile(child) else { continue }
            sources.append(FileRepresentationSource(
                url: child,
                name: child.lastPathComponent,
                relativePath: relativePath(of: child, under: url, root: root)
            ))
        }
        return sources
    }

    private static func relativePath(of child: URL, under directory: URL, root: String) -> String {
        let base = directory.standardizedFileURL.pathComponents
        let tail = child.standardizedFileURL.pathComponents.dropFirst(base.count)
        return ([root] + tail).joined(separator: "/")
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    private static func isRegularFile(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
    }
}
