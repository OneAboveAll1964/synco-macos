import Foundation

enum TimeLimit {
    static func run<Value: Sendable>(
        _ duration: Duration,
        operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        try await withThrowingTaskGroup(of: Value.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: duration)
                throw TransportError.timedOut
            }
            guard let result = try await group.next() else {
                throw TransportError.timedOut
            }
            group.cancelAll()
            return result
        }
    }
}
