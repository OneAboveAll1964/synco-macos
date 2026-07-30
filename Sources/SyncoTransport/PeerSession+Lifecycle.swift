import Foundation
import SyncoCore
import SyncoCrypto

extension PeerSession {
    func run() async {
        do {
            try await connection.start()
            let outcome = try await TimeLimit.run(configuration.handshakeTimeout) {
                try await self.performHandshake()
            }
            switch outcome {
            case .session(let peer, let result):
                await establish(peer: peer, result: result)
                try await runReceiveLoop()
            case .unpaired(let peer, let pendingRequest):
                let settlement = try await TimeLimit.run(configuration.pairingTimeout) {
                    try await self.runPairingExchange(peer: peer, pendingRequest: pendingRequest)
                }
                emit(.pairingSettled(settlement))
                await finish(reason: .unpaired)
            }
        } catch {
            let reason = CloseReasonMapping.reason(for: error)
            SyncoLog.session.info(
                "session \(self.peerDescription, privacy: .public) ended \(reason.rawValue, privacy: .public): \(String(describing: error), privacy: .public)"
            )
            await finish(reason: reason)
        }
    }

    private func establish(peer: PeerDescriptor, result: HandshakeResult) async {
        await channel.activate(
            sendCipher: result.makeSendCipher(),
            receiveCipher: result.makeReceiveCipher()
        )
        lastInbound = .now
        lastOutbound = .now
        emit(.established(peer, result.role))
        startKeepalive()
        startWatchdog()
    }
}
