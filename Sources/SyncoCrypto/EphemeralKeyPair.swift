import CryptoKit
import Foundation
import SyncoCore

public struct EphemeralKeyPair: Hashable, Sendable {
    public let publicKey: Data
    let privateKey: Data

    private init(privateKey: Data, publicKey: Data) {
        self.privateKey = privateKey
        self.publicKey = publicKey
    }

    public static func generate() -> EphemeralKeyPair {
        let key = Curve25519.KeyAgreement.PrivateKey()
        return EphemeralKeyPair(
            privateKey: key.rawRepresentation,
            publicKey: key.publicKey.rawRepresentation
        )
    }

    static func restored(privateKeyRepresentation: Data) throws -> EphemeralKeyPair {
        do {
            let key = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKeyRepresentation)
            return EphemeralKeyPair(
                privateKey: key.rawRepresentation,
                publicKey: key.publicKey.rawRepresentation
            )
        } catch {
            throw SyncoError.invalidIdentityKey
        }
    }
}
