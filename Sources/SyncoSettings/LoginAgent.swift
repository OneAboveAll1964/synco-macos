import Foundation
import SyncoCore

public enum LoginAgent {

    public static func isInstalled(fileManager: FileManager = .default) -> Bool {
        fileManager.fileExists(atPath: plistURL().path)
    }

    public static func install(
        executable: URL,
        fileManager: FileManager = .default
    ) throws {
        let directory = LoginAgentPlist.directory()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try LoginAgentPlist.data(executable: executable).write(to: plistURL(), options: .atomic)
        bootstrap()
        SyncoLog.settings.notice("Synco will now open at login")
    }

    public static func remove(fileManager: FileManager = .default) throws {
        guard isInstalled(fileManager: fileManager) else { return }
        bootout()
        try fileManager.removeItem(at: plistURL())
        SyncoLog.settings.notice("Synco will no longer open at login")
    }

    static func plistURL() -> URL {
        LoginAgentPlist.url(in: LoginAgentPlist.directory())
    }

    private static func bootstrap() {
        run(["bootout", target], ignoringFailure: true)
        run(["bootstrap", domain, plistURL().path])
    }

    private static func bootout() {
        run(["bootout", target], ignoringFailure: true)
    }

    private static var domain: String { "gui/\(getuid())" }

    private static var target: String { "\(domain)/\(LoginAgentPlist.label)" }

    private static func run(_ arguments: [String], ignoringFailure: Bool = false) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return }
        process.waitUntilExit()
        guard !ignoringFailure, process.terminationStatus != 0 else { return }
        SyncoLog.settings.error(
            "launchctl \(arguments.first ?? "", privacy: .public) exited \(process.terminationStatus)"
        )
    }
}
