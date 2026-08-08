import Foundation
import SyncoCore
import SyncoCrypto

public enum SessionEvent: Sendable {
    case established(PeerDescriptor, HandshakeRole)
    case control(ControlMessage)
    case blobChunk(BlobChunk)
    case media(MediaFrame)
    case pairingProposed(PairingProposal)
    case pairingSettled(PairingSettlement)
    case ended(CloseReason)

    public var terminalReason: CloseReason? {
        guard case .ended(let reason) = self else { return nil }
        return reason
    }

    public var controlMessage: ControlMessage? {
        guard case .control(let message) = self else { return nil }
        return message
    }
}
