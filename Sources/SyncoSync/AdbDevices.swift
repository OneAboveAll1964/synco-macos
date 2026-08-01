import Foundation

enum AdbDevices {

    static func serials(in output: String) -> [String] {
        output
            .split(separator: "\n")
            .dropFirst()
            .compactMap { line in
                let columns = line.split(separator: "\t", omittingEmptySubsequences: true)
                guard columns.count == 2, columns[1].trimmingCharacters(in: .whitespaces) == "device"
                else {
                    return nil
                }
                return String(columns[0]).trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }
}
