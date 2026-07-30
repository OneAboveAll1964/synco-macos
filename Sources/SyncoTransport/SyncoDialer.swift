import Foundation
import Network
import SyncoCore

public struct SyncoDialer: Sendable {
    public static let defaultTimeout = Duration.seconds(10)

    private let parameters: NWParameters
    private let timeout: Duration
    private let maxPayloadBytes: Int

    public init(
        parameters: NWParameters = SyncoNetworkParameters.tcp(),
        timeout: Duration = SyncoDialer.defaultTimeout,
        maxPayloadBytes: Int = SyncoConstants.Framing.maxPayloadBytes
    ) {
        self.parameters = parameters
        self.timeout = timeout
        self.maxPayloadBytes = maxPayloadBytes
    }

    public func connect(to endpoint: NWEndpoint) async throws -> FramedConnection {
        let connection = FramedConnection(
            connection: NWConnection(to: endpoint, using: parameters),
            maxPayloadBytes: maxPayloadBytes
        )
        do {
            try await TimeLimit.run(timeout) { try await connection.start() }
        } catch {
            connection.close()
            throw error
        }
        return connection
    }
}
