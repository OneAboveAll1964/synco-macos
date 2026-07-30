import Foundation
import SyncoRuntime

struct StubProcessLiveness: ProcessLiveness {
    let runningPIDs: Set<pid_t>

    init(runningPIDs: Set<pid_t> = []) {
        self.runningPIDs = runningPIDs
    }

    func isRunning(_ pid: pid_t) -> Bool {
        runningPIDs.contains(pid)
    }
}
