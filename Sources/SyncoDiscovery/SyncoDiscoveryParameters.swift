import Foundation
import Network

public enum SyncoDiscoveryParameters {
    public static func browse() -> NWParameters {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        return parameters
    }
}
