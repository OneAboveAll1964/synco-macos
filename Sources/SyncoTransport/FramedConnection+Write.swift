import Foundation
import Network
import SyncoCore

extension FramedConnection {
    public nonisolated var isTerminated: Bool {
        termination.failure != nil
    }

    public nonisolated func write(frame payload: Data) throws -> FrameWriteReceipt {
        let encoded = try FrameCodec.encode(payload, maxPayloadBytes: maxPayloadBytes)
        let receipt = FrameWriteReceipt()
        if let failure = termination.failure {
            receipt.complete(.failure(failure))
            return receipt
        }
        let token = termination.register { receipt.complete(.failure($0)) }
        connection.send(content: encoded, completion: .contentProcessed { [termination] error in
            defer { termination.unregister(token) }
            guard let error else {
                receipt.complete(.success(()))
                return
            }
            let failure = TransportError.connectionFailed(String(describing: error))
            termination.fail(with: failure)
            receipt.complete(.failure(failure))
        })
        return receipt
    }

    public nonisolated func send(frame payload: Data) async throws {
        try await write(frame: payload).wait()
    }

    public nonisolated func close() {
        termination.fail(with: TransportError.connectionClosed)
        connection.cancel()
    }
}
