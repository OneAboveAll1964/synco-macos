import Foundation

public struct ChangeCountMonitor: Sendable {
    public static let pollInterval: Duration = .milliseconds(350)

    private let counter: any PasteboardChangeCounting
    private let interval: Duration

    public init(
        counter: any PasteboardChangeCounting = SystemPasteboardChangeCounter(),
        interval: Duration = ChangeCountMonitor.pollInterval
    ) {
        self.counter = counter
        self.interval = interval
    }

    public var currentChangeCount: Int { counter.currentChangeCount }

    public func changes() -> AsyncStream<Int> {
        let counter = self.counter
        let interval = self.interval
        let (stream, continuation) = AsyncStream<Int>.makeStream()
        let task = Task.detached(priority: .utility) {
            var previous = counter.currentChangeCount
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    break
                }
                let current = counter.currentChangeCount
                guard current != previous else { continue }
                previous = current
                continuation.yield(current)
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }
}
