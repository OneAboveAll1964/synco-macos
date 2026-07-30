import Foundation
import SyncoCore
import SyncoCrypto

extension PeerSession {
    func runPairingExchange(
        peer: PeerDescriptor,
        pendingRequest: PairRequestMessage?
    ) async throws -> PairingSettlement {
        try await channel.send(ControlMessage.pairRequest(localPairRequest()))
        let request: PairRequestMessage
        if let pendingRequest {
            request = pendingRequest
        } else {
            request = try await receivePairRequest()
        }
        let proposal = try PairingProposal(request: request)
        guard proposal.deviceID == peer.deviceID else {
            throw SyncoError.didMismatch
        }
        emit(.pairingProposed(proposal))
        let decision = await configuration.pairingApproval.pairingDecision(for: proposal)
        try await channel.send(ControlMessage.pairResponse(localPairResponse(decision: decision)))
        let response = try await receivePairResponse()
        return PairingSettlement(
            proposal: proposal,
            localDecision: decision,
            peerAccepted: response.accepted && response.deviceID == peer.deviceID
        )
    }

    private func localPairRequest() -> PairRequestMessage {
        PairRequestMessage(
            deviceID: configuration.identity.deviceID,
            displayName: configuration.localHelloDisplayName,
            platform: .current,
            staticPublicKey: configuration.identity.publicKey,
            fingerprint: configuration.identity.fingerprint
        )
    }

    private func localPairResponse(decision: PairingDecision) -> PairResponseMessage {
        PairResponseMessage(
            accepted: decision.accepted,
            deviceID: configuration.identity.deviceID,
            staticPublicKey: configuration.identity.publicKey
        )
    }

    private func receivePairRequest() async throws -> PairRequestMessage {
        while true {
            switch try await channel.receiveControlMessage() {
            case .pairRequest(let request):
                return request
            case .bye(let bye):
                throw TransportError.peerClosed(bye.reason)
            case .auth, .hello, .unknown:
                continue
            case let other:
                throw TransportError.unexpectedHandshakeMessage(other.typeIdentifier)
            }
        }
    }

    private func receivePairResponse() async throws -> PairResponseMessage {
        while true {
            switch try await channel.receiveControlMessage() {
            case .pairResponse(let response):
                return response
            case .bye(let bye):
                throw TransportError.peerClosed(bye.reason)
            case .auth, .hello, .pairRequest, .unknown:
                continue
            case let other:
                throw TransportError.unexpectedHandshakeMessage(other.typeIdentifier)
            }
        }
    }
}
