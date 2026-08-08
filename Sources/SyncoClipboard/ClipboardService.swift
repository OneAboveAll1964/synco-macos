import Foundation
import SyncoCore

public actor ClipboardService {
    public nonisolated let deviceID: DeviceID
    public nonisolated let suppression: SuppressionWindow

    private let monitor: ChangeCountMonitor
    private let reader: PasteboardReader
    private let writer: PasteboardWriter
    private var lastSentHash: String?
    private var lastKnownChangeCount: Int
    private var observation: Task<Void, Never>?

    public init(
        deviceID: DeviceID,
        monitor: ChangeCountMonitor = ChangeCountMonitor(),
        reader: PasteboardReader = PasteboardReader(),
        writer: PasteboardWriter = PasteboardWriter(),
        suppression: SuppressionWindow = SuppressionWindow()
    ) {
        self.deviceID = deviceID
        self.monitor = monitor
        self.reader = reader
        self.writer = writer
        self.suppression = suppression
        lastKnownChangeCount = monitor.currentChangeCount
    }

    public func localClips() -> AsyncStream<LocalClip> {
        observation?.cancel()
        let changes = monitor.changes()
        let (stream, continuation) = AsyncStream<LocalClip>.makeStream()
        observation = Task { [weak self] in
            for await changeCount in changes {
                guard let self else { break }
                if let clip = await self.observe(changeCount: changeCount) {
                    continuation.yield(clip)
                }
            }
            continuation.finish()
        }
        return stream
    }

    public func currentClip() async -> LocalClip? {
        let capture = await PasteboardCapture.systemPasteboard()
        lastKnownChangeCount = capture.changeCount
        return await clip(from: capture)
    }

    func currentClipForEchoCheck() async -> LocalClip? {
        let capture = await PasteboardCapture.systemPasteboard()
        return await clip(from: capture)
    }

    public func apply(_ clip: ClipMessage, receivedFiles: [TransferID: URL]) async -> Bool {
        guard clip.origin != deviceID else { return false }
        await suppression.remember(clip.hash)
        let applied = ClipCanonicalHash.hexDigest(for: clip.representations)
        if applied != clip.hash {
            await suppression.remember(applied)
        }
        _ = await writer.applyToSystemPasteboard(
            clip.representations,
            receivedFiles: receivedFiles
        )
        await rememberWrittenClip()
        return true
    }

    private func rememberWrittenClip() async {
        let capture = await PasteboardCapture.systemPasteboard()
        lastKnownChangeCount = capture.changeCount
        let readback = reader.read(capture)
        if !readback.isEmpty {
            await suppression.remember(readback.canonicalHash)
        }
    }

    public func noteSent(hash: String) {
        lastSentHash = hash
    }

    public func clearSentHistory() {
        lastSentHash = nil
    }

    public func stop() {
        observation?.cancel()
        observation = nil
    }

    private func observe(changeCount: Int) async -> LocalClip? {
        guard changeCount != lastKnownChangeCount else { return nil }
        lastKnownChangeCount = changeCount
        let capture = await PasteboardCapture.systemPasteboard()
        return await clip(from: capture)
    }

    private func clip(from capture: PasteboardCapture) async -> LocalClip? {
        guard !capture.isEmpty else { return nil }
        let snapshot = reader.read(capture)
        guard !snapshot.isEmpty else { return nil }
        let hash = snapshot.canonicalHash
        guard hash != lastSentHash, await suppression.contains(hash) == false else { return nil }
        return LocalClip(origin: deviceID, snapshot: snapshot)
    }
}
