import Foundation

public protocol PairingApprovalProviding: Sendable {
    func pairingDecision(for proposal: PairingProposal) async -> PairingDecision
}
