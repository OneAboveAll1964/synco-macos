import Foundation
import SyncoCore
import SyncoCrypto

public actor PeerSession {
    let connection: FramedConnection
    let channel: SessionChannel
    let configuration: PeerSessionConfiguration

    var events: AsyncStream<SessionEvent>.Continuation?
    var lifecycle: Task<Void, Never>?
    var keepalive: Task<Void, Never>?
    var watchdog: Task<Void, Never>?
    var lastInbound = ContinuousClock.now
    var lastOutbound = ContinuousClock.now
    var pingSequence = 0
    var didFinish = false

    public init(connection: FramedConnection, configuration: PeerSessionConfiguration) {
        self.connection = connection
        self.configuration = configuration
        channel = SessionChannel(connection: connection)
    }

    public nonisolated var peerDescription: String {
        connection.peerDescription
    }

    public func start() -> AsyncStream<SessionEvent> {
        let (stream, continuation) = AsyncStream<SessionEvent>.makeStream()
        guard lifecycle == nil, !didFinish else {
            continuation.finish()
            return stream
        }
        events = continuation
        lifecycle = Task { await self.run() }
        return stream
    }

    public func send(_ message: ControlMessage) async throws {
        try await channel.send(message)
        lastOutbound = .now
    }

    public func send(_ chunk: BlobChunk) async throws {
        try await channel.send(try chunk.framePayload())
        lastOutbound = .now
    }

    public func send(_ frame: MediaFrame) async throws {
        try await channel.send(FramePayload.media(frame.encoded()))
        lastOutbound = .now
    }

    public func close(reason: CloseReason = .shutdown) async {
        await finish(reason: reason)
        lifecycle?.cancel()
    }

    func emit(_ event: SessionEvent) {
        events?.yield(event)
    }

    func finish(reason: CloseReason, announcing: Bool = true) async {
        guard !didFinish else { return }
        didFinish = true
        keepalive?.cancel()
        watchdog?.cancel()
        if announcing {
            try? await channel.send(ControlMessage.bye(ByeMessage(reason: reason)))
        }
        connection.close()
        emit(.ended(reason))
        events?.finish()
        events = nil
    }
}
