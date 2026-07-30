import Foundation
import SyncoCore
import SyncoCrypto

enum HandshakeOutcome: Sendable {
    case session(PeerDescriptor, HandshakeResult)
    case unpaired(PeerDescriptor, PairRequestMessage?)
}
