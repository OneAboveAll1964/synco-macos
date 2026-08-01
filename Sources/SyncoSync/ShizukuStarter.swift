import Foundation

public struct ShizukuStarter: Sendable {

    public static let startScript =
        "/storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh"

    private let adb: URL?

    public init(adb: URL? = AdbLocator.locate()) {
        self.adb = adb
    }

    public func start() async -> ShizukuStartOutcome {
        guard let adb else { return .adbMissing }
        let command = AdbCommand(adb: adb)
        guard let devices = command.run(["devices"]) else { return .failed }
        guard hasDevice(devices) else { return .noDevice }
        guard command.run(["shell", "sh", Self.startScript], timeout: 40) != nil else {
            return .failed
        }
        return isRunning(command) ? .started : .failed
    }

    private func isRunning(_ command: AdbCommand) -> Bool {
        guard let processes = command.run(["shell", "ps", "-A", "-o", "NAME"]) else { return false }
        return processes.contains("shizuku_server")
    }

    private func hasDevice(_ output: String) -> Bool {
        output
            .split(separator: "\n")
            .dropFirst()
            .contains { $0.hasSuffix("\tdevice") }
    }
}
