import Foundation
import SyncoCore
import SyncoCrypto

actor SessionChannel {
    private let connection: FramedConnection
    private var sendCipher: SessionCipher?
    private var receiveCipher: SessionCipher?

    init(connection: FramedConnection) {
        self.connection = connection
    }

    var isEncrypted: Bool {
        sendCipher != nil && receiveCipher != nil
    }

    func activate(sendCipher: SessionCipher, receiveCipher: SessionCipher) {
        self.sendCipher = sendCipher
        self.receiveCipher = receiveCipher
    }

    func send(_ payload: FramePayload) async throws {
        try await issue(payload).wait()
    }

    func send(_ message: ControlMessage) async throws {
        try await send(SyncoJSON.controlFrame(message))
    }

    func receive() async throws -> FramePayload {
        let frame = try await connection.receiveFrame()
        guard receiveCipher != nil else {
            return try FramePayload.decode(frame)
        }
        guard let plaintext = try receiveCipher?.open(frame) else {
            throw SyncoError.malformedRecord
        }
        return try FramePayload.decode(plaintext)
    }

    func receiveControlMessage() async throws -> ControlMessage {
        try SyncoJSON.controlMessage(from: try await receive())
    }

    private func issue(_ payload: FramePayload) throws -> FrameWriteReceipt {
        let encoded = payload.encoded()
        guard sendCipher != nil else {
            return try connection.write(frame: encoded)
        }
        guard let record = try sendCipher?.seal(encoded) else {
            throw SyncoError.malformedRecord
        }
        return try connection.write(frame: record)
    }
}
