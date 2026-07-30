import Foundation
import SyncoCore
import SyncoTransport

extension PeerRegistry {
    func connection(for deviceID: DeviceID) -> PeerConnection {
        if let existing = connections[deviceID] { return existing }
        let created = PeerConnection(
            deviceID: deviceID,
            localDeviceID: localDeviceID,
            policy: document.policy(for: deviceID),
            registry: self,
            factory: factory,
            dialer: dialer,
            driver: driver,
            transfers: transfers,
            clipboard: clipboard
        )
        connections[deviceID] = created
        return created
    }

    func plan(_ deviceID: DeviceID) async {
        let existing = connections[deviceID]
        let action = reconciliation.plan(
            discovered: discovered[deviceID],
            isTrusted: document.peer(deviceID)?.isUsable ?? false,
            hasLiveSession: await existing?.isLive ?? false
        )
        switch action {
        case .unpaired:
            guard let existing else { return }
            await existing.close(reason: .unpaired)
            connections.removeValue(forKey: deviceID)
            backoffs.removeValue(forKey: deviceID)
        case .standby:
            await existing?.apply(plan: action)
        case .dial, .awaitPeer:
            await connection(for: deviceID).apply(plan: action)
        }
    }

    func nextRetryDelay(for deviceID: DeviceID) -> Duration {
        var backoff = backoffs[deviceID] ?? Backoff()
        let delay = backoff.nextDelay()
        backoffs[deviceID] = backoff
        return delay
    }

    func resetRetryDelay(for deviceID: DeviceID) {
        backoffs[deviceID] = Backoff()
    }
}
