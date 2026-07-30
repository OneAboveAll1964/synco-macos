import Foundation

public final class SingleInstanceGuard {
    private let lock: any InstanceLocking

    public init(lock: any InstanceLocking = FileInstanceLock()) {
        self.lock = lock
    }

    public func admit() -> InstanceAdmission {
        switch lock.acquire() {
        case .acquired:
            return .granted
        case .alreadyRunning(let pid):
            return .refused(existing: pid)
        case .unavailable(let reason):
            return .degraded(reason)
        }
    }

    public func relinquish() {
        lock.release()
    }
}
