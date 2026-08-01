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
        guard case .success(let devices) = run(adb, ["devices"]) else { return .failed }
        guard hasDevice(devices) else { return .noDevice }
        guard case .success(let output) = run(adb, ["shell", "sh", Self.startScript]) else {
            return .failed
        }
        return output.localizedCaseInsensitiveContains("info: shizuku_starter exit with 0")
            || output.localizedCaseInsensitiveContains("start Shizuku")
            ? .started
            : .failed
    }

    private func hasDevice(_ output: String) -> Bool {
        output
            .split(separator: "\n")
            .dropFirst()
            .contains { $0.hasSuffix("\tdevice") }
    }

    private func run(_ executable: URL, _ arguments: [String]) -> Result<String, Never>? {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        guard (try? process.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return .success(String(decoding: data, as: UTF8.self))
    }
}
