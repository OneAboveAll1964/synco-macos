import Foundation
import SyncoClipboard
import SyncoCore

public protocol ClipboardApplying: Sendable {
    func apply(_ clip: ClipMessage, receivedFiles: [TransferID: URL]) async -> Bool
    func noteSent(hash: String) async
}

extension ClipboardService: ClipboardApplying {}
