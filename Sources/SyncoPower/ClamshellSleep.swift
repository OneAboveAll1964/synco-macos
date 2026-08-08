import Foundation
import SyncoCore

public enum ClamshellSleep {
    public static let settingKey = "SleepDisabled"

    public static func parse(_ output: String) -> Bool? {
        for line in output.split(separator: "\n") {
            let fields = line.split(whereSeparator: \.isWhitespace)
            guard fields.count == 2, fields[0] == settingKey else { continue }
            return fields[1] == "1"
        }
        return nil
    }

    public static func script(disablingSleep disabled: Bool) -> String {
        "do shell script \"/usr/bin/pmset -a disablesleep \(disabled ? 1 : 0)\""
            + " with administrator privileges"
    }

    public static func current() -> Bool {
        guard let output = read() else { return false }
        return parse(output) ?? false
    }

    private static func read() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            SyncoLog.settings.error("pmset read failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }
}
