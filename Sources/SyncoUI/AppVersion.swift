import Foundation

enum AppVersion {
    static let string: String = {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String
        return short ?? "development"
    }()
}
