import Foundation
import Network
import SyncoCore

public actor SyncoListener {
    public nonisolated let nwListener: NWListener

    private let queue = DispatchQueue(label: "app.synco.transport.listener")
    private let termination = TerminationRegistry()
    private let accepted: AsyncStream<FramedConnection>
    private let acceptedContinuation: AsyncStream<FramedConnection>.Continuation
    private var didStart = false

    public init(
        parameters: NWParameters = SyncoNetworkParameters.tcp(),
        port: NWEndpoint.Port = .any,
        maxPayloadBytes: Int = SyncoConstants.Framing.maxPayloadBytes
    ) throws {
        let listener = try Self.makeListener(parameters: parameters, port: port)
        let (stream, continuation) = AsyncStream<FramedConnection>.makeStream()
        nwListener = listener
        accepted = stream
        acceptedContinuation = continuation
        listener.newConnectionHandler = { connection in
            continuation.yield(
                FramedConnection(connection: connection, maxPayloadBytes: maxPayloadBytes)
            )
        }
    }

    private static func makeListener(
        parameters: NWParameters,
        port: NWEndpoint.Port
    ) throws -> NWListener {
        do {
            return try NWListener(using: parameters, on: port)
        } catch {
            throw TransportError.listenerUnavailable(String(describing: error))
        }
    }

    public nonisolated var port: UInt16? {
        nwListener.port?.rawValue
    }

    public func connections() -> AsyncStream<FramedConnection> {
        accepted
    }

    public func start() async throws -> UInt16 {
        guard !didStart else { return try boundPort() }
        didStart = true
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let ready = SingleResume(continuation)
                _ = termination.register { ready.fail($0) }
                nwListener.stateUpdateHandler = { [termination] state in
                    switch state {
                    case .ready:
                        ready.succeed(())
                    case .failed(let error):
                        termination.fail(with: TransportError.listenerFailed(String(describing: error)))
                    case .cancelled:
                        termination.fail(with: TransportError.connectionClosed)
                    default:
                        break
                    }
                }
                nwListener.start(queue: queue)
            }
        } onCancel: { [nwListener] in
            nwListener.cancel()
        }
        return try boundPort()
    }

    public nonisolated func stop() {
        termination.fail(with: TransportError.connectionClosed)
        acceptedContinuation.finish()
        nwListener.cancel()
    }

    private func boundPort() throws -> UInt16 {
        guard let value = nwListener.port?.rawValue, value != 0 else {
            throw TransportError.listenerWithoutPort
        }
        return value
    }
}
