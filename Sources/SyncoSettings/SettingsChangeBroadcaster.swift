import Foundation

public actor SettingsChangeBroadcaster {
    private var observers: [UUID: AsyncStream<SettingsDocument>.Continuation] = [:]
    private var latest: SettingsDocument?

    public init() {}

    public func stream() -> AsyncStream<SettingsDocument> {
        let identifier = UUID()
        let (stream, continuation) = AsyncStream<SettingsDocument>.makeStream()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(identifier) }
        }
        if let latest {
            continuation.yield(latest)
        }
        observers[identifier] = continuation
        return stream
    }

    public func publish(_ document: SettingsDocument) {
        latest = document
        for continuation in observers.values {
            continuation.yield(document)
        }
    }

    public func finish() {
        for continuation in observers.values {
            continuation.finish()
        }
        observers.removeAll()
    }

    private func removeObserver(_ identifier: UUID) {
        observers.removeValue(forKey: identifier)
    }
}
