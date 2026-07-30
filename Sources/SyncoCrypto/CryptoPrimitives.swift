import CryptoKit
import Foundation
import SyncoCore

public enum CryptoPrimitives {
    public static func sha256(_ data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }

    public static func hmacSHA256(key: Data, message: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: key)))
    }

    public static func hkdfSHA256(ikm: Data, salt: Data, info: Data, length: Int) -> Data {
        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: ikm),
            salt: salt,
            info: info,
            outputByteCount: length
        )
        return derived.withUnsafeBytes { Data($0) }
    }

    public static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var difference: UInt8 = 0
        for (left, right) in zip(lhs, rhs) {
            difference |= left ^ right
        }
        return difference == 0
    }

    public static func randomBytes(_ count: Int) -> Data {
        SymmetricKey(size: SymmetricKeySize(bitCount: count * 8)).withUnsafeBytes { Data($0) }
    }

    public static func keyAgreement(privateKey: Data, peerPublicKey: Data) throws -> Data {
        do {
            let staticKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey)
            let peer = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKey)
            let shared = try staticKey.sharedSecretFromKeyAgreement(with: peer)
            let bytes = shared.withUnsafeBytes { Data($0) }
            guard bytes.count == SyncoConstants.Handshake.sharedSecretBytes,
                  bytes.contains(where: { $0 != 0 })
            else {
                throw SyncoError.badHandshake
            }
            return bytes
        } catch let error as SyncoError {
            throw error
        } catch {
            throw SyncoError.badHandshake
        }
    }
}
