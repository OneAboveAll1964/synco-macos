import Foundation

public struct SignalProcessLiveness: ProcessLiveness {
    public init() {}

    public func isRunning(_ pid: pid_t) -> Bool {
        guard pid > 0 else { return false }
        guard kill(pid, 0) != 0 else { return true }
        return errno == EPERM
    }
}
