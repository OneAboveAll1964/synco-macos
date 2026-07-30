import Foundation

public struct PairingSettlement: Hashable, Sendable {
    public let proposal: PairingProposal
    public let localDecision: PairingDecision
    public let peerAccepted: Bool

    public init(proposal: PairingProposal, localDecision: PairingDecision, peerAccepted: Bool) {
        self.proposal = proposal
        self.localDecision = localDecision
        self.peerAccepted = peerAccepted
    }

    public var isAgreed: Bool {
        localDecision.accepted && peerAccepted
    }
}
