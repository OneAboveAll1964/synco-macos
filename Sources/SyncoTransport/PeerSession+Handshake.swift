import Foundation
import SyncoCore
import SyncoCrypto

extension PeerSession {
    func performHandshake() async throws -> HandshakeOutcome {
        let ephemeral = EphemeralKeyPair.generate()
        try await channel.send(ControlMessage.hello(localHello(ephemeral: ephemeral)))
        let hello = try await receivePeerHello()
        let peer = PeerDescriptor(hello: hello)
        guard hello.version == SyncoConstants.protocolVersion else {
            throw SyncoError.versionMismatch(hello.version)
        }
        guard hello.deviceID != configuration.identity.deviceID else {
            throw SyncoError.selfConnection
        }
        guard let trusted = await configuration.trustedPeers.trustedPeer(for: hello.deviceID) else {
            return .unpaired(peer, nil)
        }
        guard trusted.keyMatchesDeviceID else {
            throw SyncoError.unknownKey
        }
        let result = try Handshake.derive(
            role: HandshakeRole.role(
                localDeviceID: configuration.identity.deviceID,
                peerDeviceID: hello.deviceID
            ),
            identity: configuration.identity,
            ephemeral: ephemeral,
            peerDeviceID: hello.deviceID,
            peerStaticPublicKey: trusted.staticPublicKey,
            peerEphemeralPublicKey: hello.ephemeralPublicKey
        )
        try await channel.send(ControlMessage.auth(result.authMessage))
        return try await confirmPeerAuth(result: result, peer: peer)
    }

    func localHello(ephemeral: EphemeralKeyPair) -> HelloMessage {
        HelloMessage(
            deviceID: configuration.identity.deviceID,
            displayName: configuration.localHelloDisplayName,
            platform: .current,
            ephemeralPublicKey: ephemeral.publicKey
        )
    }

    private func receivePeerHello() async throws -> HelloMessage {
        while true {
            switch try await channel.receiveControlMessage() {
            case .hello(let hello):
                return hello
            case .bye(let bye):
                throw TransportError.peerClosed(bye.reason)
            case .unknown:
                continue
            case let other:
                throw TransportError.unexpectedHandshakeMessage(other.typeIdentifier)
            }
        }
    }

    private func confirmPeerAuth(
        result: HandshakeResult,
        peer: PeerDescriptor
    ) async throws -> HandshakeOutcome {
        while true {
            switch try await channel.receiveControlMessage() {
            case .auth(let auth):
                try result.requirePeerConfirmationTag(auth.tag)
                return .session(peer, result)
            case .pairRequest(let request):
                return .unpaired(peer, request)
            case .bye(let bye):
                throw TransportError.peerClosed(bye.reason)
            case .unknown:
                continue
            case let other:
                throw TransportError.unexpectedHandshakeMessage(other.typeIdentifier)
            }
        }
    }
}
