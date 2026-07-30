import Foundation
import SyncoCore

public enum ClipTypeCategory: String, Hashable, Sendable, CaseIterable, Identifiable {
    case text
    case image
    case file

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .text: return "Text"
        case .image: return "Images"
        case .file: return "Files"
        }
    }

    public func isEnabled(in flags: ClipTypeFlags) -> Bool {
        switch self {
        case .text: return flags.text
        case .image: return flags.image
        case .file: return flags.file
        }
    }

    public func set(_ enabled: Bool, in flags: inout ClipTypeFlags) {
        switch self {
        case .text: flags.text = enabled
        case .image: flags.image = enabled
        case .file: flags.file = enabled
        }
    }

    public func updating(_ flags: ClipTypeFlags, enabled: Bool) -> ClipTypeFlags {
        var updated = flags
        set(enabled, in: &updated)
        return updated
    }
}
