import Foundation
import SyncoCore
import SyncoTransport

struct SessionDriver: Sendable {
    let registry: PeerRegistry
    let pairing: PairingCoordinator

    @discardableResult
    func run(session: PeerSession, origin: SessionOrigin) async -> CloseReason? {
        var binding: PeerBinding?
        var outcome: CloseReason?
        for await event in await session.start() {
            switch event {
            case .established(let descriptor, _):
                guard let adopted = await registry.bind(
                    descriptor: descriptor,
                    session: session,
                    origin: origin
                ) else {
                    await session.close(reason: .duplicateSession)
                    return .duplicateSession
                }
                binding = adopted
                try? await adopted.router.announceCapabilities()
            case .control(let message):
                guard let binding else { continue }
                await forward(await binding.router.handle(message))
            case .blobChunk(let chunk):
                guard let binding else { continue }
                await forward(await binding.router.accept(chunk))
            case .media:
                continue
            case .pairingProposed(let proposal):
                await pairing.present(proposal)
            case .pairingSettled(let settlement):
                await pairing.settle(settlement)
            case .ended(let reason):
                outcome = reason
                await registry.sessionEnded(
                    deviceID: binding?.deviceID,
                    origin: origin,
                    reason: reason
                )
            }
        }
        return outcome
    }

    private func forward(_ event: SyncEvent?) async {
        guard let event else { return }
        await registry.report(event)
    }
}
