import Foundation
import Network
import SyncoCore
@testable import SyncoTransport

struct LoopbackConnectionPair {
    let listener: SyncoListener
    let client: FramedConnection
    let server: FramedConnection

    func close() {
        client.close()
        server.close()
        listener.stop()
    }
}

enum Loopback {
    static let acceptTimeout = Duration.seconds(5)

    static func pair(
        clientMaxPayloadBytes: Int = SyncoConstants.Framing.maxPayloadBytes,
        serverMaxPayloadBytes: Int = SyncoConstants.Framing.maxPayloadBytes
    ) async throws -> LoopbackConnectionPair {
        let listener = try SyncoListener(maxPayloadBytes: serverMaxPayloadBytes)
        let port = try await listener.start()
        let stream = await listener.connections()
        async let accepted = firstConnection(from: stream)
        let dialer = SyncoDialer(timeout: acceptTimeout, maxPayloadBytes: clientMaxPayloadBytes)
        let client = try await dialer.connect(to: endpoint(port: port))
        let server = try await accepted
        try await server.start()
        return LoopbackConnectionPair(listener: listener, client: client, server: server)
    }

    private static func endpoint(port: UInt16) -> NWEndpoint {
        .hostPort(host: .ipv4(.loopback), port: NWEndpoint.Port(rawValue: port) ?? .any)
    }

    private static func firstConnection(
        from stream: AsyncStream<FramedConnection>
    ) async throws -> FramedConnection {
        try await TimeLimit.run(acceptTimeout) { () async throws -> FramedConnection in
            for await connection in stream {
                return connection
            }
            throw TransportError.connectionClosed
        }
    }
}
