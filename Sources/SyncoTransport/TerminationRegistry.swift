import Foundation

final class TerminationRegistry: @unchecked Sendable {
    typealias FailureHook = @Sendable (any Error) -> Void

    private let lock = NSLock()
    private var hooks: [Int: FailureHook] = [:]
    private var lastToken = 0
    private var storedFailure: (any Error)?

    var failure: (any Error)? {
        lock.lock()
        defer { lock.unlock() }
        return storedFailure
    }

    func register(_ hook: @escaping FailureHook) -> Int {
        lock.lock()
        if let storedFailure {
            lock.unlock()
            hook(storedFailure)
            return 0
        }
        lastToken += 1
        let token = lastToken
        hooks[token] = hook
        lock.unlock()
        return token
    }

    func unregister(_ token: Int) {
        lock.lock()
        hooks[token] = nil
        lock.unlock()
    }

    func fail(with error: any Error) {
        lock.lock()
        let failure = storedFailure ?? error
        storedFailure = failure
        let pending = Array(hooks.values)
        hooks.removeAll()
        lock.unlock()
        for hook in pending {
            hook(failure)
        }
    }
}
