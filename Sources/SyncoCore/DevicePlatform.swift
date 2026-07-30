import Foundation

public enum DevicePlatform: String, Codable, Sendable, Hashable, CaseIterable {
    case macOS = "macos"
    case android = "android"

    public static let current: DevicePlatform = .macOS

    public var displayName: String {
        switch self {
        case .macOS: return "Mac"
        case .android: return "Android"
        }
    }
}
