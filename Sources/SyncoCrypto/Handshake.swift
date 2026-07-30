import Foundation
import SyncoCore

public enum Handshake {
    public static func derive(
        role: HandshakeRole,
        identity: DeviceIdentity,
        ephemeral: EphemeralKeyPair,
        peerDeviceID: DeviceID,
        peerStaticPublicKey: Data,
        peerEphemeralPublicKey: Data
    ) throws -> HandshakeResult {
        let sharedEphemeral = try CryptoPrimitives.keyAgreement(
            privateKey: ephemeral.privateKey,
            peerPublicKey: peerEphemeralPublicKey
        )
        let sharedStaticEphemeral: Data
        let sharedEphemeralStatic: Data
        switch role {
        case .initiator:
            sharedStaticEphemeral = try CryptoPrimitives.keyAgreement(
                privateKey: identity.privateKey,
                peerPublicKey: peerEphemeralPublicKey
            )
            sharedEphemeralStatic = try CryptoPrimitives.keyAgreement(
                privateKey: ephemeral.privateKey,
                peerPublicKey: peerStaticPublicKey
            )
        case .responder:
            sharedStaticEphemeral = try CryptoPrimitives.keyAgreement(
                privateKey: ephemeral.privateKey,
                peerPublicKey: peerStaticPublicKey
            )
            sharedEphemeralStatic = try CryptoPrimitives.keyAgreement(
                privateKey: identity.privateKey,
                peerPublicKey: peerEphemeralPublicKey
            )
        }
        var inputKeyMaterial = sharedEphemeral
        inputKeyMaterial.append(sharedStaticEphemeral)
        inputKeyMaterial.append(sharedEphemeralStatic)
        guard inputKeyMaterial.count == SyncoConstants.Handshake.inputKeyMaterialBytes else {
            throw SyncoError.badHandshake
        }
        let keyMaterial = CryptoPrimitives.hkdfSHA256(
            ikm: inputKeyMaterial,
            salt: salt(localDeviceID: identity.deviceID, peerDeviceID: peerDeviceID),
            info: SyncoConstants.Handshake.hkdfInfo,
            length: SyncoConstants.Handshake.keyMaterialBytes
        )
        let sessionKeyBytes = SyncoConstants.Handshake.sessionKeyBytes
        let initiatorToResponder = Data(keyMaterial.prefix(sessionKeyBytes))
        let responderToInitiator = Data(keyMaterial.suffix(sessionKeyBytes))
        let sendKey = role == .initiator ? initiatorToResponder : responderToInitiator
        let receiveKey = role == .initiator ? responderToInitiator : initiatorToResponder
        return HandshakeResult(
            role: role,
            sendKey: sendKey,
            receiveKey: receiveKey,
            confirmationTag: confirmationTag(key: sendKey, deviceID: identity.deviceID),
            expectedPeerConfirmationTag: confirmationTag(key: receiveKey, deviceID: peerDeviceID)
        )
    }

    public static func salt(localDeviceID: DeviceID, peerDeviceID: DeviceID) -> Data {
        let lower = min(localDeviceID, peerDeviceID)
        let upper = max(localDeviceID, peerDeviceID)
        var material = Data(lower.rawValue.utf8)
        material.append(contentsOf: upper.rawValue.utf8)
        return CryptoPrimitives.sha256(material)
    }

    public static func confirmationTag(key: Data, deviceID: DeviceID) -> Data {
        var message = SyncoConstants.Handshake.confirmationPrefix
        message.append(contentsOf: deviceID.rawValue.utf8)
        return CryptoPrimitives.hmacSHA256(key: key, message: message)
    }
}
