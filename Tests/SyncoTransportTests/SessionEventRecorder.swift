import Foundation
@testable import SyncoTransport

struct RecorderTimeout: Error {}

actor SessionEventRecorder {
    private var received: [SessionEvent] = []
    private var consumer: Task<Void, Never>?

    func consume(_ stream: AsyncStream<SessionEvent>) {
        consumer = Task { [weak self] in
            for await event in stream {
                await self?.append(event)
            }
        }
    }

    func stop() {
        consumer?.cancel()
        consumer = nil
    }

    func snapshot() -> [SessionEvent] {
        received
    }

    func wait<Value: Sendable>(
        timeout: Duration = .seconds(5),
        for transform: @Sendable (SessionEvent) -> Value?
    ) async throws -> Value {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if let value = received.compactMap(transform).first {
                return value
            }
            try await Task.sleep(for: .milliseconds(5))
        }
        throw RecorderTimeout()
    }

    private func append(_ event: SessionEvent) {
        received.append(event)
    }
}
