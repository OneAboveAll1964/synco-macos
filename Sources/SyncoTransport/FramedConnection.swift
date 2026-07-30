import Foundation
import Network
import SyncoCore

public actor FramedConnection {
    private static let receiveChunkBytes = 65_536

    public nonisolated let peerDescription: String

    let connection: NWConnection
    let maxPayloadBytes: Int
    let termination = TerminationRegistry()

    private let queue: DispatchQueue
    private var decoder: FrameCodec.Decoder
    private var pendingFrames: [Data] = []
    private var readFailure: (any Error)?
    private var didStart = false

    public init(
        connection: NWConnection,
        maxPayloadBytes: Int = SyncoConstants.Framing.maxPayloadBytes
    ) {
        self.connection = connection
        self.maxPayloadBytes = maxPayloadBytes
        peerDescription = String(describing: connection.endpoint)
        queue = DispatchQueue(label: "com.shkomaghdid.synco.macos.transport.connection")
        decoder = FrameCodec.Decoder(maxPayloadBytes: maxPayloadBytes)
    }

    deinit {
        connection.cancel()
    }

    public func start() async throws {
        guard !didStart else { return }
        didStart = true
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let ready = SingleResume(continuation)
                _ = termination.register { ready.fail($0) }
                connection.stateUpdateHandler = { [termination] state in
                    switch state {
                    case .ready:
                        ready.succeed(())
                    case .failed(let error):
                        termination.fail(with: TransportError.connectionFailed(String(describing: error)))
                    case .cancelled:
                        termination.fail(with: TransportError.connectionClosed)
                    default:
                        break
                    }
                }
                connection.start(queue: queue)
            }
        } onCancel: { [connection] in
            connection.cancel()
        }
    }

    public func receiveFrame() async throws -> Data {
        while true {
            if !pendingFrames.isEmpty {
                return pendingFrames.removeFirst()
            }
            if let readFailure {
                throw readFailure
            }
            if let failure = termination.failure {
                throw failure
            }
            let chunk = try await receiveChunk()
            do {
                pendingFrames.append(contentsOf: try decoder.push(chunk))
            } catch {
                readFailure = error
                throw error
            }
        }
    }

    private func receiveChunk() async throws -> Data {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, any Error>) in
                let pending = SingleResume(continuation)
                let token = termination.register { pending.fail($0) }
                connection.receive(
                    minimumIncompleteLength: 1,
                    maximumLength: Self.receiveChunkBytes
                ) { [termination] content, _, isComplete, error in
                    defer { termination.unregister(token) }
                    if let error {
                        let failure = TransportError.connectionFailed(String(describing: error))
                        termination.fail(with: failure)
                        pending.fail(failure)
                        return
                    }
                    if let content, !content.isEmpty {
                        pending.succeed(content)
                        return
                    }
                    if isComplete {
                        termination.fail(with: TransportError.connectionClosed)
                    }
                    pending.fail(TransportError.connectionClosed)
                }
            }
        } onCancel: { [connection] in
            connection.cancel()
        }
    }
}
