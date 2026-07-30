import CryptoKit
import Foundation
import SyncoCore

public struct DeviceIdentity: Hashable, Sendable {
    public let publicKey: Data
    public let deviceID: DeviceID
    public let fingerprint: Fingerprint
    let privateKey: Data

    init(privateKeyRepresentation: Data) throws {
        let key = try Self.parse(privateKeyRepresentation)
        let publicKey = key.publicKey.rawRepresentation
        let digest = CryptoPrimitives.sha256(publicKey)
        self.privateKey = privateKeyRepresentation
        self.publicKey = publicKey
        deviceID = try Self.deviceID(fromDigest: digest)
        fingerprint = try Self.fingerprint(fromDigest: digest)
    }

    public static func generate() throws -> DeviceIdentity {
        try DeviceIdentity(privateKeyRepresentation: Curve25519.KeyAgreement.PrivateKey().rawRepresentation)
    }

    public static func deviceID(forStaticPublicKey publicKey: Data) throws -> DeviceID {
        try deviceID(fromDigest: CryptoPrimitives.sha256(publicKey))
    }

    public static func fingerprint(forStaticPublicKey publicKey: Data) throws -> Fingerprint {
        try fingerprint(fromDigest: CryptoPrimitives.sha256(publicKey))
    }

    public static func staticPublicKey(_ publicKey: Data, matches deviceID: DeviceID) -> Bool {
        guard publicKey.count == SyncoConstants.Identity.publicKeyBytes,
              let derived = try? Self.deviceID(forStaticPublicKey: publicKey)
        else {
            return false
        }
        return derived == deviceID
    }

    private static func deviceID(fromDigest digest: Data) throws -> DeviceID {
        let prefix = digest.prefix(SyncoConstants.Identity.deviceIDDigestPrefixBytes)
        return try DeviceID(validating: Base32.encode(Data(prefix)))
    }

    private static func fingerprint(fromDigest digest: Data) throws -> Fingerprint {
        let prefix = digest.prefix(SyncoConstants.Identity.fingerprintDigestPrefixBytes)
        return try Fingerprint(digestPrefix: Data(prefix))
    }

    private static func parse(_ representation: Data) throws -> Curve25519.KeyAgreement.PrivateKey {
        do {
            return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: representation)
        } catch {
            throw SyncoError.invalidIdentityKey
        }
    }
}
