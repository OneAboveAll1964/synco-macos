import Foundation
import Network
import SyncoCore
import SyncoTransport

extension PeerConnection {
    func apply(plan: PeerLinkPlan) async {
        switch plan {
        case .dial(let target):
            endpoint = target
            guard origin == nil, !dialing else { return }
            status = .connecting
            startDialing()
        case .awaitPeer:
            endpoint = nil
            stopDialing()
            guard origin == nil else { return }
            status = .waitingForPeer
        case .standby:
            guard origin == nil else { return }
            endpoint = nil
            stopDialing()
            status = .idle
        case .unpaired:
            await close(reason: .unpaired)
            status = .unpaired
        }
    }

    func stopDialing() {
        dialGeneration += 1
        dialing = false
        dialTask?.cancel()
        dialTask = nil
    }

    func statusAfterEnd(_ reason: CloseReason) -> PeerLinkStatus {
        if reason == .unpaired { return .unpaired }
        if endpoint != nil, decision == .dial { return .connecting }
        return decision == .wait ? .waitingForPeer : .closed(reason)
    }

    private func startDialing() {
        dialGeneration += 1
        dialing = true
        let generation = dialGeneration
        dialTask?.cancel()
        dialTask = Task { [weak self] in
            guard let self else { return }
            await self.dialLoop(generation: generation)
        }
    }

    private func dialLoop(generation: Int) async {
        while !Task.isCancelled, generation == dialGeneration {
            guard origin == nil, let target = endpoint else { break }
            await attemptDial(to: target)
            guard !Task.isCancelled, generation == dialGeneration, origin == nil, endpoint != nil
            else {
                break
            }
            let delay = await registry.nextRetryDelay(for: deviceID)
            status = .retrying(delay)
            await registry.refreshPeers()
            do {
                try await Task.sleep(for: delay)
            } catch {
                break
            }
        }
        endDialing(generation: generation)
    }

    private func attemptDial(to target: NWEndpoint) async {
        status = .connecting
        await registry.refreshPeers()
        do {
            let connection = try await dialer.connect(to: target)
            let session = await factory.session(for: connection)
            await driver.run(session: session, origin: .dialed)
        } catch {
            status = .closed(Self.failureReason(error))
            SyncoLog.session.info(
                "dial to \(self.deviceID.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)"
            )
        }
    }

    private func endDialing(generation: Int) {
        guard generation == dialGeneration else { return }
        dialing = false
        dialTask = nil
    }

    private static func failureReason(_ error: any Error) -> CloseReason {
        if let transportError = error as? TransportError { return transportError.closeReason }
        if let syncoError = error as? SyncoError, let reason = syncoError.closeReason { return reason }
        return .shutdown
    }
}
