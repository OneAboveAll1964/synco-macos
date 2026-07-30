import Foundation

public enum SyncPermissionProblem: Hashable, Sendable {
    case localNetworkUnavailable
    case listenerUnavailable(String)
    case identityUnavailable(String)

    public var title: String {
        switch self {
        case .localNetworkUnavailable: return "No local network"
        case .listenerUnavailable: return "Cannot accept connections"
        case .identityUnavailable: return "Identity unavailable"
        }
    }

    public var detail: String {
        switch self {
        case .localNetworkUnavailable:
            return "Synco needs a Wi-Fi or Ethernet connection and permission to find devices on your local network."
        case .listenerUnavailable(let description):
            return description
        case .identityUnavailable(let description):
            return description
        }
    }
}
