import SyncoRuntime

final class StubInstanceLock: InstanceLocking {
    private let outcome: InstanceLockOutcome
    private(set) var acquireCount = 0
    private(set) var releaseCount = 0

    init(outcome: InstanceLockOutcome) {
        self.outcome = outcome
    }

    func acquire() -> InstanceLockOutcome {
        acquireCount += 1
        return outcome
    }

    func release() {
        releaseCount += 1
    }
}
