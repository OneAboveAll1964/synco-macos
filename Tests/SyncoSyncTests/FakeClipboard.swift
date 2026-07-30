import Foundation
import SyncoCore
@testable import SyncoSync

actor FakeClipboard: ClipboardApplying {
    struct Application: Sendable {
        let clip: ClipMessage
        let receivedFiles: [TransferID: URL]
    }

    private(set) var applications: [Application] = []
    private(set) var sentHashes: [String] = []
    private var outcome = true

    func apply(_ clip: ClipMessage, receivedFiles: [TransferID: URL]) async -> Bool {
        applications.append(Application(clip: clip, receivedFiles: receivedFiles))
        return outcome
    }

    func noteSent(hash: String) async {
        sentHashes.append(hash)
    }

    func setOutcome(_ value: Bool) {
        outcome = value
    }

    func appliedClips() -> [ClipMessage] {
        applications.map(\.clip)
    }

    func appliedFiles() -> [[TransferID: URL]] {
        applications.map(\.receivedFiles)
    }

    func recordedSentHashes() -> [String] {
        sentHashes
    }
}
