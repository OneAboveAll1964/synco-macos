import Foundation

enum LoginAgentPlist {

    static let label = "com.shkomaghdid.synco.macos.login"

    static func url(in directory: URL) -> URL {
        directory.appendingPathComponent("\(label).plist")
    }

    static func directory(home: URL = URL(fileURLWithPath: NSHomeDirectory())) -> URL {
        home.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }

    static func contents(executable: URL) -> [String: Any] {
        [
            "Label": label,
            "ProgramArguments": [executable.path],
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProcessType": "Interactive",
            "LimitLoadToSessionType": "Aqua",
        ]
    }

    static func data(executable: URL) throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: contents(executable: executable),
            format: .xml,
            options: 0
        )
    }
}
