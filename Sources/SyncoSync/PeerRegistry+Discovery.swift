import Foundation
import SyncoCore
import SyncoDiscovery
import SyncoSettings
import SyncoTransport

extension PeerRegistry: PeerReconnecting {
    public func apply(_ event: DiscoveryEvent) async {
        switch event {
        case .peerAppeared(let peer), .peerChanged(let peer):
            guard peer.deviceID != localDeviceID else { return }
            discovered[peer.deviceID] = peer
        case .peerDisappeared(let deviceID):
            discovered.removeValue(forKey: deviceID)
            backoffs.removeValue(forKey: deviceID)
        }
        await plan(event.deviceID)
        await refreshPeers()
    }

    public func apply(_ document: SettingsDocument) async {
        self.document = document
        for (deviceID, connection) in connections {
            await connection.update(policy: document.policy(for: deviceID))
        }
        var identifiers = Set(document.peers.map(\.deviceID))
        identifiers.formUnion(connections.keys)
        identifiers.formUnion(discovered.keys)
        for deviceID in identifiers {
            await plan(deviceID)
        }
        await refreshPeers()
    }

    public func adoptInbound(_ connection: FramedConnection) {
        let identifier = UUID()
        let driver = self.driver
        let factory = self.factory
        inboundTasks[identifier] = Task { [weak self] in
            let session = await factory.session(for: connection)
            await driver.run(session: session, origin: .accepted)
            await self?.finishInbound(identifier)
        }
    }

    public func reconnect(_ deviceID: DeviceID) async {
        resetRetryDelay(for: deviceID)
        await plan(deviceID)
        await refreshPeers()
    }

    public func beginPairing(with deviceID: DeviceID) async {
        guard let peer = discovered[deviceID] else { return }
        guard document.peer(deviceID)?.isUsable != true else {
            await reconnect(deviceID)
            return
        }
        await pairing.clearRejection(deviceID)
        let driver = self.driver
        let factory = self.factory
        let dialer = self.dialer
        pairingTasks[deviceID]?.cancel()
        pairingTasks[deviceID] = Task { [weak self] in
            do {
                let dialed = try await dialer.connect(to: peer.endpoint)
                let session = await factory.session(for: dialed)
                await driver.run(session: session, origin: .dialed)
            } catch {
                SyncoLog.session.info(
                    "pairing dial to \(deviceID.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)"
                )
            }
            await self?.finishPairing(deviceID)
        }
    }

    public func closeAll(reason: CloseReason) async {
        for task in inboundTasks.values {
            task.cancel()
        }
        for task in pairingTasks.values {
            task.cancel()
        }
        inboundTasks.removeAll()
        pairingTasks.removeAll()
        for connection in connections.values {
            await connection.close(reason: reason)
        }
        connections.removeAll()
        discovered.removeAll()
        backoffs.removeAll()
        await refreshPeers()
    }

    func finishInbound(_ identifier: UUID) {
        inboundTasks.removeValue(forKey: identifier)
    }

    func finishPairing(_ deviceID: DeviceID) {
        pairingTasks.removeValue(forKey: deviceID)
    }
}
