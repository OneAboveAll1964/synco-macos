import Foundation
import SyncoCore

public enum HandshakeRole: String, Hashable, Sendable, CaseIterable {
    case initiator
    case responder

    public static func role(localDeviceID: DeviceID, peerDeviceID: DeviceID) -> HandshakeRole {
        localDeviceID.isInitiator(against: peerDeviceID) ? .initiator : .responder
    }

    public var peerRole: HandshakeRole {
        self == .initiator ? .responder : .initiator
    }
}
