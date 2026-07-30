import Foundation

public final class FrameWriteReceipt: @unchecked Sendable {
    private let lock = NSLock()
    private var outcome: Result<Void, any Error>?
    private var waiter: CheckedContinuation<Void, any Error>?

    init() {}

    public func wait() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            lock.lock()
            if let outcome {
                lock.unlock()
                continuation.resume(with: outcome)
                return
            }
            waiter = continuation
            lock.unlock()
        }
    }

    func complete(_ result: Result<Void, any Error>) {
        lock.lock()
        guard outcome == nil else {
            lock.unlock()
            return
        }
        outcome = result
        let pending = waiter
        waiter = nil
        lock.unlock()
        pending?.resume(with: result)
    }
}
