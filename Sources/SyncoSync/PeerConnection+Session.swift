import Foundation
import SyncoCore
import SyncoSettings
import SyncoTransport

extension PeerConnection {
    func adopt(
        session incoming: PeerSession,
        origin incomingOrigin: SessionOrigin,
        policy newPolicy: SyncPolicy
    ) async -> ClipRouter {
        await displace(replacedBy: incoming, incomingOrigin: incomingOrigin)
        policy = newPolicy
        session = incoming
        origin = incomingOrigin
        status = .online
        let adopted = ClipRouter(
            localDeviceID: localDeviceID,
            peerDeviceID: deviceID,
            transport: incoming,
            clipboard: clipboard,
            transfers: transfers,
            policy: newPolicy
        )
        router = adopted
        return adopted
    }

    func sessionEnded(origin endedOrigin: SessionOrigin, reason: CloseReason) async {
        guard origin == endedOrigin else { return }
        await releaseSession()
        status = statusAfterEnd(reason)
    }

    func releaseSession() async {
        await router?.reset()
        router = nil
        session = nil
        origin = nil
    }

    private func displace(replacedBy incoming: PeerSession, incomingOrigin: SessionOrigin) async {
        if incomingOrigin == .accepted {
            stopDialing()
        }
        guard let existing = session, existing !== incoming else { return }
        await router?.reset()
        router = nil
        await existing.close(reason: .duplicateSession)
    }
}
