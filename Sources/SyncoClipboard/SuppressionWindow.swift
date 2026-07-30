import Foundation
import SyncoCore

public actor SuppressionWindow {
    public nonisolated let capacity: Int
    public nonisolated let lifetime: Duration

    private let clock = ContinuousClock()
    private var entries: [(hash: String, recordedAt: ContinuousClock.Instant)] = []

    public init(
        capacity: Int = SyncoConstants.Limits.suppressionWindowEntries,
        lifetime: Duration = SyncoConstants.Timing.suppressionWindow
    ) {
        self.capacity = max(1, capacity)
        self.lifetime = lifetime
    }

    public func remember(_ hash: String) {
        purge()
        entries.removeAll { $0.hash == hash }
        entries.append((hash: hash, recordedAt: clock.now))
        while entries.count > capacity {
            entries.removeFirst()
        }
    }

    public func remember(contentsOf hashes: [String]) {
        for hash in hashes {
            remember(hash)
        }
    }

    public func contains(_ hash: String) -> Bool {
        purge()
        return entries.contains { $0.hash == hash }
    }

    public func consume(_ hash: String) -> Bool {
        guard contains(hash) else { return false }
        entries.removeAll { $0.hash == hash }
        return true
    }

    public func count() -> Int {
        purge()
        return entries.count
    }

    public func removeAll() {
        entries.removeAll()
    }

    private func purge() {
        let now = clock.now
        entries.removeAll { $0.recordedAt.duration(to: now) > lifetime }
    }
}
