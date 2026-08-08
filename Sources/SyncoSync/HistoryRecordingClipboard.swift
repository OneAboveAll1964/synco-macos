import Foundation
import SyncoCore

struct HistoryRecordingClipboard: ClipboardApplying {
    let delegate: any ClipboardApplying
    let history: ClipHistoryStore

    func apply(_ clip: ClipMessage, receivedFiles: [TransferID: URL]) async -> Bool {
        let applied = await delegate.apply(clip, receivedFiles: receivedFiles)
        if applied {
            await history.record(representations: clip.representations, fromPeer: true)
        }
        return applied
    }

    func noteSent(hash: String) async {
        await delegate.noteSent(hash: hash)
    }
}
