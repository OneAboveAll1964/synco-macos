import Foundation
import SyncoCore

public struct ShizukuStarter: Sendable {

    private let adb: URL?

    public init(adb: URL? = AdbLocator.locate()) {
        self.adb = adb
    }

    public func start() async -> ShizukuStartOutcome {
        guard let adb else {
            SyncoLog.session.info("no adb on this Mac, cannot start Shizuku")
            return .adbMissing
        }
        let command = AdbCommand(adb: adb)
        guard let listing = command.run(["devices"]) else { return .failed }
        let serials = AdbDevices.serials(in: listing)
        guard !serials.isEmpty else { return .noDevice }
        SyncoLog.session.info("starting Shizuku over adb on \(serials.count, privacy: .public) device(s)")
        return outcome(across: serials, using: command)
    }

    private func outcome(across serials: [String], using command: AdbCommand) -> ShizukuStartOutcome {
        var best = ShizukuStartOutcome.failed
        for serial in serials {
            let arguments = ["-s", serial, "shell", ShizukuStartScript.shell]
            guard let output = command.run(arguments, timeout: 90) else { continue }
            let result = Self.outcome(of: output)
            if result == .started { return .started }
            best = Self.preferred(best, result)
        }
        return best
    }

    static func preferred(_ current: ShizukuStartOutcome, _ next: ShizukuStartOutcome) -> ShizukuStartOutcome {
        rank(next) > rank(current) ? next : current
    }

    private static func rank(_ outcome: ShizukuStartOutcome) -> Int {
        switch outcome {
        case .started: return 3
        case .noStarter: return 2
        case .notInstalled: return 1
        default: return 0
        }
    }

    static func outcome(of output: String) -> ShizukuStartOutcome {
        if output.contains(ShizukuStartScript.successMarker) { return .started }
        if output.contains(ShizukuStartScript.notInstalledMarker) { return .notInstalled }
        if output.contains(ShizukuStartScript.noStarterMarker) { return .noStarter }
        return .failed
    }
}
