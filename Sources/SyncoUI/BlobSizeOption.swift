import Foundation

enum BlobSizeOption: Int64, CaseIterable, Identifiable {
    case tenMegabytes = 10_485_760
    case fiftyMegabytes = 52_428_800
    case hundredMegabytes = 104_857_600
    case twoHundredFiftyMegabytes = 262_144_000
    case fiveHundredMegabytes = 524_288_000
    case oneGigabyte = 1_073_741_824
    case unlimited = 9_223_372_036_854_775_807

    var id: Int64 { rawValue }

    var title: String { self == .unlimited ? "No limit" : ByteSizeText.string(rawValue) }

    static func nearest(_ bytes: Int64) -> BlobSizeOption {
        let clamped = max(0, bytes)
        return allCases.min {
            distance(from: $0, to: clamped) < distance(from: $1, to: clamped)
        } ?? .hundredMegabytes
    }

    private static func distance(from option: BlobSizeOption, to bytes: Int64) -> UInt64 {
        option.rawValue > bytes
            ? UInt64(option.rawValue - bytes)
            : UInt64(bytes - option.rawValue)
    }
}
