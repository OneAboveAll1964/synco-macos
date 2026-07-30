import Foundation
import SyncoCore

public struct HandshakeResult: Hashable, Sendable {
    public let role: HandshakeRole
    public let sendKey: Data
    public let receiveKey: Data
    public let confirmationTag: Data
    public let expectedPeerConfirmationTag: Data

    public func verifyPeerConfirmationTag(_ tag: Data) -> Bool {
        CryptoPrimitives.constantTimeEquals(expectedPeerConfirmationTag, tag)
    }

    public func requirePeerConfirmationTag(_ tag: Data) throws {
        guard verifyPeerConfirmationTag(tag) else { throw SyncoError.badAuth }
    }

    public func makeSendCipher() -> SessionCipher {
        SessionCipher(key: sendKey)
    }

    public func makeReceiveCipher() -> SessionCipher {
        SessionCipher(key: receiveKey)
    }

    public var authMessage: AuthMessage {
        AuthMessage(tag: confirmationTag)
    }
}
