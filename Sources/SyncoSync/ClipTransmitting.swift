import Foundation
import SyncoCore
import SyncoTransport

public protocol ClipTransmitting: Sendable {
    func send(_ message: ControlMessage) async throws
    func send(_ chunk: BlobChunk) async throws
    func send(_ frame: MediaFrame) async throws
}

extension PeerSession: ClipTransmitting {}
