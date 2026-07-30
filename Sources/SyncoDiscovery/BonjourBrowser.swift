import Foundation
import Network
import SyncoCore

public actor BonjourBrowser {
    private let localDeviceID: DeviceID
    private let queue = DispatchQueue(label: "com.shkomaghdid.synco.macos.discovery.browser")
    private var browser: NWBrowser?
    private var events: AsyncStream<DiscoveryEvent>.Continuation?
    private var known: [DeviceID: DiscoveredPeer] = [:]

    public init(localDeviceID: DeviceID) {
        self.localDeviceID = localDeviceID
    }

    public func start() -> AsyncStream<DiscoveryEvent> {
        stop()
        let (stream, continuation) = AsyncStream<DiscoveryEvent>.makeStream()
        events = continuation
        let browser = NWBrowser(
            for: .bonjourWithTXTRecord(
                type: SyncoConstants.Discovery.serviceType,
                domain: SyncoConstants.Discovery.domain
            ),
            using: SyncoDiscoveryParameters.browse()
        )
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { await self?.apply(results: results) }
        }
        browser.stateUpdateHandler = { [weak self] state in
            guard case .failed = state else { return }
            Task { await self?.stop() }
        }
        self.browser = browser
        browser.start(queue: queue)
        return stream
    }

    public func stop() {
        browser?.stateUpdateHandler = nil
        browser?.browseResultsChangedHandler = nil
        browser?.cancel()
        browser = nil
        known.removeAll()
        events?.finish()
        events = nil
    }

    public var peers: [DiscoveredPeer] {
        Array(known.values)
    }

    private func apply(results: Set<NWBrowser.Result>) {
        var seen: [DeviceID: DiscoveredPeer] = [:]
        for result in results {
            guard let peer = peer(from: result), peer.deviceID != localDeviceID else { continue }
            seen[peer.deviceID] = peer
        }
        for deviceID in known.keys where seen[deviceID] == nil {
            events?.yield(.peerDisappeared(deviceID))
        }
        for (deviceID, peer) in seen {
            guard let existing = known[deviceID] else {
                events?.yield(.peerAppeared(peer))
                continue
            }
            if !existing.announcesSameState(as: peer) {
                events?.yield(.peerChanged(peer))
            }
        }
        known = seen
    }

    private func peer(from result: NWBrowser.Result) -> DiscoveredPeer? {
        guard case .bonjour(let record) = result.metadata else { return nil }
        guard let advertisement = try? TXTRecordCodec.advertisement(from: record) else { return nil }
        return DiscoveredPeer(advertisement: advertisement, endpoint: result.endpoint)
    }
}
