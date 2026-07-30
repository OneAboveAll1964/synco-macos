import Foundation

public enum InstanceLockOutcome: Equatable, Sendable {
    case acquired
    case alreadyRunning(pid: pid_t?)
    case unavailable(String)
}
