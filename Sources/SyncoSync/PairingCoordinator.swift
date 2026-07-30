import Foundation
import SyncoCore
import SyncoSettings
import SyncoTransport

public actor PairingCoordinator: PairingApprovalProviding {
    private let state: SyncState
    private let settings: SettingsStore
    private var waiters: [DeviceID: CheckedContinuation<PairingDecision, Never>] = [:]
    private var proposals: [DeviceID: PairingProposal] = [:]
    private var rejected: Set<DeviceID> = []
    private var reconnector: (any PeerReconnecting)?

    public init(state: SyncState, settings: SettingsStore) {
        self.state = state
        self.settings = settings
    }

    public func attach(reconnector: any PeerReconnecting) {
        self.reconnector = reconnector
    }

    public func pairingDecision(for proposal: PairingProposal) async -> PairingDecision {
        guard !rejected.contains(proposal.deviceID) else { return .reject }
        await present(proposal)
        return await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<PairingDecision, Never>) in
                waiters[proposal.deviceID] = continuation
            }
        } onCancel: {
            Task { await self.resolve(proposal.deviceID, decision: .reject) }
        }
    }

    public func present(_ proposal: PairingProposal) async {
        proposals[proposal.deviceID] = proposal
        await state.present(PairingRequestSnapshot(proposal: proposal))
    }

    public func approve(_ deviceID: DeviceID) async {
        rejected.remove(deviceID)
        await resolve(deviceID, decision: .approve)
    }

    public func reject(_ deviceID: DeviceID) async {
        rejected.insert(deviceID)
        await resolve(deviceID, decision: .reject)
        try? await settings.setRejected(true, for: deviceID)
    }

    public func clearRejection(_ deviceID: DeviceID) async {
        rejected.remove(deviceID)
        try? await settings.setRejected(false, for: deviceID)
    }

    public func settle(_ settlement: PairingSettlement) async {
        let proposal = settlement.proposal
        proposals.removeValue(forKey: proposal.deviceID)
        await resolve(proposal.deviceID, decision: settlement.localDecision)
        await state.dismissPairing(proposal.deviceID)
        guard settlement.isAgreed else {
            await state.record(SyncEvent(peerDeviceID: proposal.deviceID, kind: .pairingRejected))
            return
        }
        await persist(proposal)
    }

    private func persist(_ proposal: PairingProposal) async {
        do {
            _ = try await settings.trust(
                deviceID: proposal.deviceID,
                staticPublicKey: proposal.staticPublicKey,
                displayName: proposal.displayName,
                platform: proposal.platform
            )
            await state.record(SyncEvent(peerDeviceID: proposal.deviceID, kind: .paired))
            await reconnector?.reconnect(proposal.deviceID)
        } catch {
            SyncoLog.session.error(
                "pairing persistence failed: \(String(describing: error), privacy: .public)"
            )
        }
    }

    private func resolve(_ deviceID: DeviceID, decision: PairingDecision) async {
        guard let waiter = waiters.removeValue(forKey: deviceID) else { return }
        await state.dismissPairing(deviceID)
        waiter.resume(returning: decision)
    }
}
