import Foundation
import Network
import SyncoCore

public enum SyncoNetworkParameters {
    public static func tcp() -> NWParameters {
        let options = NWProtocolTCP.Options()
        options.noDelay = true
        options.enableKeepalive = true
        options.keepaliveIdle = Int(SyncoConstants.Timing.pingIntervalSeconds)
        options.keepaliveInterval = Int(SyncoConstants.Timing.pingIntervalSeconds)
        options.keepaliveCount = 3
        options.connectionTimeout = Int(SyncoConstants.Timing.readTimeoutSeconds)
        let parameters = NWParameters(tls: nil, tcp: options)
        parameters.includePeerToPeer = true
        parameters.serviceClass = .responsiveData
        return parameters
    }
}
