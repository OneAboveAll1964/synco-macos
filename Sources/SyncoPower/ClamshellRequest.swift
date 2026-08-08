import Foundation
import SyncoCore

@MainActor
public enum ClamshellRequest {
    public enum Outcome: Sendable, Equatable {
        case applied
        case declined
        case unchanged
    }

    public static func apply(_ disabled: Bool) -> Outcome {
        guard ClamshellSleep.current() != disabled else { return .unchanged }
        guard let script = NSAppleScript(source: ClamshellSleep.script(disablingSleep: disabled)) else {
            return .declined
        }
        var failure: NSDictionary?
        script.executeAndReturnError(&failure)
        if let failure {
            SyncoLog.settings.notice("clamshell change refused: \(String(describing: failure), privacy: .public)")
            return .declined
        }
        return .applied
    }
}
