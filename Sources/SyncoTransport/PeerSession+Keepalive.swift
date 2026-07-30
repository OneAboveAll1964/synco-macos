import Foundation
import SyncoCore

extension PeerSession {
    var isFinished: Bool {
        didFinish
    }

    func startKeepalive() {
        keepalive?.cancel()
        keepalive = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if await self.isFinished { return }
                let remaining = await self.writeIdleBudget()
                if remaining <= .zero {
                    await self.sendKeepalivePing()
                    continue
                }
                do {
                    try await Task.sleep(for: remaining)
                } catch {
                    return
                }
            }
        }
    }

    func startWatchdog() {
        watchdog?.cancel()
        watchdog = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if await self.isFinished { return }
                let remaining = await self.readBudget()
                if remaining <= .zero {
                    await self.finish(reason: .timeout)
                    return
                }
                do {
                    try await Task.sleep(for: remaining)
                } catch {
                    return
                }
            }
        }
    }

    func writeIdleBudget() -> Duration {
        configuration.pingInterval - (ContinuousClock.now - lastOutbound)
    }

    func readBudget() -> Duration {
        configuration.readTimeout - (ContinuousClock.now - lastInbound)
    }

    func sendKeepalivePing() async {
        guard !didFinish else { return }
        pingSequence += 1
        lastOutbound = .now
        do {
            try await send(ControlMessage.ping(PingMessage(seq: pingSequence)))
        } catch {
            await finish(reason: CloseReasonMapping.reason(for: error))
        }
    }
}
