import Foundation
@testable import SyncoTransport

struct FixedPairingApproval: PairingApprovalProviding {
    let decision: PairingDecision

    func pairingDecision(for proposal: PairingProposal) async -> PairingDecision {
        decision
    }
}
