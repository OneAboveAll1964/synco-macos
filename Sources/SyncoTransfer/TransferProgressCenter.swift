import Foundation
import SyncoCore

public actor TransferProgressCenter {
    private var observers: [UUID: AsyncStream<TransferProgress>.Continuation] = [:]
    private var latest: [TransferID: TransferProgress] = [:]

    public init() {}

    public func stream() -> AsyncStream<TransferProgress> {
        let identifier = UUID()
        let (stream, continuation) = AsyncStream<TransferProgress>.makeStream()
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeObserver(identifier) }
        }
        for progress in latest.values where !progress.isFinished {
            continuation.yield(progress)
        }
        observers[identifier] = continuation
        return stream
    }

    public func publish(_ progress: TransferProgress) {
        if progress.isFinished {
            latest.removeValue(forKey: progress.transferID)
        } else {
            latest[progress.transferID] = progress
        }
        for continuation in observers.values {
            continuation.yield(progress)
        }
    }

    public func active() -> [TransferProgress] {
        latest.values.sorted { $0.name < $1.name }
    }

    public func finish() {
        latest.removeAll()
        for continuation in observers.values {
            continuation.finish()
        }
        observers.removeAll()
    }

    private func removeObserver(_ identifier: UUID) {
        observers.removeValue(forKey: identifier)
    }
}
