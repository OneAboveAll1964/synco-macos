import Foundation
import SyncoCore

public struct ClipHistoryEntry: Codable, Hashable, Sendable {
    public let text: String
    public let isURL: Bool
    public let at: Date
    public let fromPeer: Bool
}

public actor ClipHistoryStore {
    public static let maxEntries = 30
    public static let maxTextCharacters = 4_096

    private let file: URL
    private var cached: [ClipHistoryEntry]?
    private var continuations: [UUID: AsyncStream<[ClipHistoryEntry]>.Continuation] = [:]

    public init(directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        file = directory.appendingPathComponent("clip-history.json")
    }

    public func entries() -> [ClipHistoryEntry] {
        if let cached { return cached }
        let loaded = (try? Data(contentsOf: file))
            .flatMap { try? JSONDecoder().decode([ClipHistoryEntry].self, from: $0) } ?? []
        cached = loaded
        return loaded
    }

    public func changes() -> AsyncStream<[ClipHistoryEntry]> {
        AsyncStream { continuation in
            let identifier = UUID()
            continuations[identifier] = continuation
            continuation.yield(entries())
            continuation.onTermination = { [weak self] _ in
                Task { await self?.drop(identifier) }
            }
        }
    }

    public func record(representations: [ClipRepresentation], fromPeer: Bool) {
        guard let entry = Self.entry(for: representations, fromPeer: fromPeer) else { return }
        var next = entries().filter { $0.text != entry.text }
        next.insert(entry, at: 0)
        next = Array(next.prefix(Self.maxEntries))
        cached = next
        try? JSONEncoder().encode(next).write(to: file, options: .atomic)
        for continuation in continuations.values {
            continuation.yield(next)
        }
    }

    static func entry(for representations: [ClipRepresentation], fromPeer: Bool) -> ClipHistoryEntry? {
        for representation in representations {
            if case .url(let link) = representation {
                return ClipHistoryEntry(text: link.url, isURL: true, at: Date(), fromPeer: fromPeer)
            }
        }
        for representation in representations {
            if case .text(let value) = representation, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return ClipHistoryEntry(
                    text: String(value.prefix(maxTextCharacters)),
                    isURL: false,
                    at: Date(),
                    fromPeer: fromPeer
                )
            }
        }
        return nil
    }

    private func drop(_ identifier: UUID) {
        continuations.removeValue(forKey: identifier)
    }
}
