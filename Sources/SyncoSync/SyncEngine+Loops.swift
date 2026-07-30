import Foundation
import SyncoCore
import SyncoDiscovery
import SyncoSettings

extension SyncEngine {
    func startLoops() {
        startBrowsing()
        tasks.append(loop { await $0.consumeConnections() })
        tasks.append(loop { await $0.consumeSettings() })
        tasks.append(loop { await $0.consumeClipboard() })
        tasks.append(loop { await $0.consumeTransferProgress() })
        tasks.append(loop { await $0.consumeNetworkPath() })
    }

    private func loop(
        _ body: @escaping @Sendable (SyncEngine) async -> Void
    ) -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }
            await body(self)
        }
    }

    func applyDocument(_ updated: SettingsDocument) async {
        document = updated
        await transfers.setMaxBlobBytes(updated.maxBlobBytes)
        await advertiser?.update(displayName: updated.displayName)
        await state.apply(
            identity: LocalIdentitySnapshot(identity: identity, displayName: updated.displayName)
        )
        await state.setPaused(updated.paused)
        await registry.apply(updated)
    }

    private func startBrowsing() {
        browseTask?.cancel()
        let browser = self.browser
        browseTask = Task { [weak self] in
            for await event in await browser.start() {
                guard let self else { return }
                await self.registry.apply(event)
            }
        }
    }

    private func consumeConnections() async {
        guard let listener else { return }
        for await connection in await listener.connections() {
            await registry.adoptInbound(connection)
        }
    }

    private func consumeSettings() async {
        for await updated in await settings.changes() {
            await applyDocument(updated)
        }
    }

    private func consumeClipboard() async {
        for await clip in await clipboard.localClips() {
            await registry.broadcast(clip)
        }
    }

    private func consumeTransferProgress() async {
        for await progress in await transfers.progressStream() {
            await state.apply(progress)
        }
    }

    private func consumeNetworkPath() async {
        for await change in await pathMonitor.start() {
            await handle(change)
        }
    }

    private func handle(_ change: NetworkPathChange) async {
        guard change.allowsLocalDiscovery else {
            pathSignature = nil
            await state.report(problem: .localNetworkUnavailable)
            return
        }
        await state.report(problem: nil)
        let previous = pathSignature
        pathSignature = change.interfaceSignature
        guard previous != nil, previous != change.interfaceSignature else { return }
        SyncoLog.discovery.info(
            "restarting discovery for \(change.interfaceSignature, privacy: .public)"
        )
        await advertiser?.restart()
        startBrowsing()
    }
}
