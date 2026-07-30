import Foundation
import SyncoCore

public struct TransferPaths: Sendable, Hashable {
    public static let receivedFolderName = "Synco"
    public static let stagingFolderName = "Staging"

    public static let shared = TransferPaths()

    public let stagingDirectory: URL
    public let receivedDirectory: URL

    public init(stagingDirectory: URL, receivedDirectory: URL) {
        self.stagingDirectory = stagingDirectory
        self.receivedDirectory = receivedDirectory
    }

    public init(containerName: String = SyncoLog.subsystem) {
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? home.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        let downloads = FileManager.default
            .urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? home.appending(path: "Downloads", directoryHint: .isDirectory)
        stagingDirectory = support
            .appending(path: containerName, directoryHint: .isDirectory)
            .appending(path: Self.stagingFolderName, directoryHint: .isDirectory)
        receivedDirectory = downloads
            .appending(path: Self.receivedFolderName, directoryHint: .isDirectory)
    }

    @discardableResult
    public func prepareStagingDirectory() throws -> URL {
        try createDirectory(stagingDirectory)
    }

    @discardableResult
    public func prepareReceivedDirectory() throws -> URL {
        try createDirectory(receivedDirectory)
    }

    public func prepareReceivedDirectory(relativePath: String?) throws -> URL {
        let root = try prepareReceivedDirectory()
        guard let relativePath else { return root }
        let folders = TransferFileName.sanitizedComponents(relativePath).dropLast()
        guard !folders.isEmpty else { return root }
        var target = root
        for folder in folders {
            target = target.appending(path: folder, directoryHint: .isDirectory)
        }
        return try createDirectory(target)
    }

    public func stagingFile(named name: String) throws -> URL {
        try prepareStagingDirectory()
            .appending(path: TransferFileName.sanitized(name), directoryHint: .notDirectory)
    }

    public func removeStagingContents() {
        let manager = FileManager.default
        let entries = try? manager.contentsOfDirectory(
            at: stagingDirectory,
            includingPropertiesForKeys: nil
        )
        for entry in entries ?? [] {
            try? manager.removeItem(at: entry)
        }
    }

    private func createDirectory(_ url: URL) throws -> URL {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
