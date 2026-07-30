import Foundation

enum ByteSizeText {
    static func string(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file))
    }

    static func progress(transferred: Int64, total: Int64) -> String {
        "\(string(transferred)) of \(string(total))"
    }
}
