import Foundation
import SyncoCore

public enum StartupConsole {
    public static func emit(_ line: String) {
        SyncoLog.app.notice("\(line, privacy: .public)")
        try? FileHandle.standardError.write(contentsOf: Data((line + "\n").utf8))
    }
}
