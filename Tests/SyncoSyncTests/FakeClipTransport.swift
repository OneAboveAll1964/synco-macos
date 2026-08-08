import Foundation
import SyncoCore
@testable import SyncoSync

actor FakeClipTransport: ClipTransmitting {
    private(set) var messages: [ControlMessage] = []
    private(set) var chunks: [BlobChunk] = []
    private(set) var frames: [MediaFrame] = []

    func send(_ message: ControlMessage) async throws {
        messages.append(message)
    }

    func send(_ chunk: BlobChunk) async throws {
        chunks.append(chunk)
    }

    func send(_ frame: MediaFrame) async throws {
        frames.append(frame)
    }

    func recordedMessages() -> [ControlMessage] {
        messages
    }

    func recordedChunks() -> [BlobChunk] {
        chunks
    }

    func acks() -> [AckMessage] {
        messages.compactMap { message in
            guard case .ack(let ack) = message else { return nil }
            return ack
        }
    }

    func clips() -> [ClipMessage] {
        messages.compactMap { message in
            guard case .clip(let clip) = message else { return nil }
            return clip
        }
    }

    func transferStarts() -> [TransferStartMessage] {
        messages.compactMap { message in
            guard case .transferStart(let start) = message else { return nil }
            return start
        }
    }

    func transferEnds() -> [TransferEndMessage] {
        messages.compactMap { message in
            guard case .transferEnd(let end) = message else { return nil }
            return end
        }
    }

    func shizukuResults() -> [ShizukuStartResultMessage] {
        messages.compactMap { message in
            guard case .shizukuStartResult(let result) = message else { return nil }
            return result
        }
    }

    func transferAborts() -> [TransferAbortMessage] {
        messages.compactMap { message in
            guard case .transferAbort(let abort) = message else { return nil }
            return abort
        }
    }
}
