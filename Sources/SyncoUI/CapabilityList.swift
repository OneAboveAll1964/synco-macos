import Foundation
import SyncoCore
import SyncoSync

enum CapabilityList {
    static func string(_ flags: ClipTypeFlags) -> String {
        let enabled = ClipTypeCategory.allCases
            .filter { $0.isEnabled(in: flags) }
            .map(\.title)
        return enabled.isEmpty ? "nothing" : enabled.joined(separator: ", ")
    }
}
