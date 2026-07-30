import Foundation

public protocol ProcessLiveness: Sendable {
    func isRunning(_ pid: pid_t) -> Bool
}
