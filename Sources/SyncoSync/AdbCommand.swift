import Foundation

struct AdbCommand: Sendable {
    let adb: URL

    func run(_ arguments: [String], timeout: TimeInterval = 25) -> String? {
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("synco-adb-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: output) }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script(arguments, output: output)]
        guard (try? process.run()) != nil else { return nil }
        guard wait(for: process, until: Date().addingTimeInterval(timeout)) else {
            process.terminate()
            return nil
        }
        return (try? String(contentsOf: output, encoding: .utf8)) ?? ""
    }

    private func script(_ arguments: [String], output: URL) -> String {
        let parts = ([adb.path] + arguments).map(quoted).joined(separator: " ")
        return "\(parts) </dev/null >\(quoted(output.path)) 2>&1"
    }

    private func quoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func wait(for process: Process, until deadline: Date) -> Bool {
        while process.isRunning {
            if Date() >= deadline { return false }
            Thread.sleep(forTimeInterval: 0.05)
        }
        return true
    }
}
