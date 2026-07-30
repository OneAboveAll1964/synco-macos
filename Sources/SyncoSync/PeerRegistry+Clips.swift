import Foundation
import SyncoClipboard
import SyncoCore

extension PeerRegistry {
    public func broadcast(_ clip: LocalClip) async {
        for connection in connections.values {
            await connection.dispatch(clip)
        }
    }

    public func cancelTransfer(_ transferID: TransferID) async {
        for connection in connections.values {
            await connection.cancelTransfer(transferID)
        }
        await transfers.abort(transferID, reason: .userCancelled)
    }

    public func report(_ event: SyncEvent) async {
        await state.record(event)
    }

    func refreshPeers() async {
        var snapshots: [PeerSnapshot] = []
        for record in document.trustedPeers {
            let link = await connections[record.deviceID]?.linkState()
            snapshots.append(PeerSnapshot(
                trusted: record,
                policy: document.directionPolicy(for: record.deviceID),
                status: link?.status ?? .idle,
                discovered: discovered[record.deviceID],
                peerCapabilities: link?.capabilities
            ))
        }
        for (deviceID, peer) in discovered where document.peer(deviceID) == nil {
            snapshots.append(PeerSnapshot(
                discovered: peer,
                policy: document.directionPolicy(for: deviceID)
            ))
        }
        await state.apply(peers: snapshots)
    }
}
