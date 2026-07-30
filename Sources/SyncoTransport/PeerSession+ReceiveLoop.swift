import Foundation
import SyncoCore

extension PeerSession {
    func runReceiveLoop() async throws {
        while !didFinish {
            let payload = try await channel.receive()
            lastInbound = .now
            switch payload.kind {
            case .blobChunk:
                emit(.blobChunk(try BlobChunk.decode(body: payload.body)))
            case .control:
                if let reason = try await handle(SyncoJSON.decode(payload.body)) {
                    await finish(reason: reason, announcing: false)
                    return
                }
            }
        }
    }

    private func handle(_ message: ControlMessage) async throws -> CloseReason? {
        switch message {
        case .ping(let ping):
            try await send(ControlMessage.pong(PongMessage(replyingTo: ping)))
            return nil
        case .pong:
            return nil
        case .bye(let bye):
            return bye.reason
        case .hello, .auth, .pairRequest, .pairResponse:
            throw TransportError.unexpectedHandshakeMessage(message.typeIdentifier)
        default:
            emit(.control(message))
            return nil
        }
    }
}
