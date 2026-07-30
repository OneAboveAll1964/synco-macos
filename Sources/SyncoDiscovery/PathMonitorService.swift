import Foundation
import Network
import SyncoCore

public actor PathMonitorService {
    private let queue = DispatchQueue(label: "app.synco.discovery.path")
    private var monitor: NWPathMonitor?
    private var events: AsyncStream<NetworkPathChange>.Continuation?
    private var latest: NetworkPathChange?

    public init() {}

    public var currentPath: NetworkPathChange? {
        latest
    }

    public func start() -> AsyncStream<NetworkPathChange> {
        stop()
        let (stream, continuation) = AsyncStream<NetworkPathChange>.makeStream()
        events = continuation
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let change = NetworkPathChange(path: path)
            Task { await self?.publish(change) }
        }
        self.monitor = monitor
        monitor.start(queue: queue)
        return stream
    }

    public func stop() {
        monitor?.pathUpdateHandler = nil
        monitor?.cancel()
        monitor = nil
        latest = nil
        events?.finish()
        events = nil
    }

    private func publish(_ change: NetworkPathChange) {
        guard change != latest else { return }
        latest = change
        SyncoLog.discovery.info(
            "network path \(change.interfaceSignature, privacy: .public) satisfied=\(change.isSatisfied, privacy: .public)"
        )
        events?.yield(change)
    }
}
