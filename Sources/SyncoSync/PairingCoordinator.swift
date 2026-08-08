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
    private var qrToken: String?

    public init(state: SyncState, settings: SettingsStore) {
        self.state = state
        self.settings = settings
    }

    public func attach(reconnector: any PeerReconnecting) {
        self.reconnector = reconnector
    }

    public func pairingDecision(for proposal: PairingProposal) async -> PairingDecision {
        if consumeQRToken(matching: proposal.token) {
            await clearRejection(proposal.deviceID)
            return .approve
        }
        guard !rejected.contains(proposal.deviceID) else { return .reject }
        if await alreadyTrusts(proposal) { return .approve }
        await present(proposal)
        return await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<PairingDecision, Never>) in
                waiters[proposal.deviceID] = continuation
            }
        } onCancel: {
            Task { await self.resolve(proposal.deviceID, decision: .reject) }
        }
    }

    public func armQRToken(_ token: String) {
        qrToken = token
    }

    public func disarmQRToken() {
        qrToken = nil
    }

    private func consumeQRToken(matching token: String?) -> Bool {
        guard let token, let armed = qrToken, token == armed else { return false }
        qrToken = nil
        return true
    }

    private func alreadyTrusts(_ proposal: PairingProposal) async -> Bool {
        guard let known = await settings.snapshot().peer(proposal.deviceID) else { return false }
        return known.isUsable && known.staticPublicKey == proposal.staticPublicKey
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
        proposals.removeValue(forKey: deviceID)
        await state.dismissPairing(deviceID)
        guard let waiter = waiters.removeValue(forKey: deviceID) else { return }
        waiter.resume(returning: decision)
    }
}
