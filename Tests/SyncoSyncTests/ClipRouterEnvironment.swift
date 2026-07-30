import Foundation
import SyncoClipboard
import SyncoCore
import SyncoSettings
import SyncoTransfer
@testable import SyncoSync

struct ClipRouterEnvironment {
    static let localDeviceID = DeviceID("aaaaaaaaaaaaaaaa")!
    static let peerDeviceID = DeviceID("zzzzzzzzzzzzzzzz")!

    let root: URL
    let paths: TransferPaths
    let transport: FakeClipTransport
    let clipboard: FakeClipboard
    let transfers: TransferManager
    let router: ClipRouter

    init(
        policy: SyncPolicy = .default,
        localDeviceID: DeviceID = ClipRouterEnvironment.localDeviceID,
        peerDeviceID: DeviceID = ClipRouterEnvironment.peerDeviceID
    ) {
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: "SyncoSyncTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let paths = TransferPaths(
            stagingDirectory: root.appending(path: "Staging", directoryHint: .isDirectory),
            receivedDirectory: root.appending(path: "Received", directoryHint: .isDirectory)
        )
        let transfers = TransferManager(
            paths: paths,
            limit: BlobSizeLimit(maxBytes: policy.maxBlobBytes)
        )
        let transport = FakeClipTransport()
        let clipboard = FakeClipboard()
        self.root = root
        self.paths = paths
        self.transfers = transfers
        self.transport = transport
        self.clipboard = clipboard
        router = ClipRouter(
            localDeviceID: localDeviceID,
            peerDeviceID: peerDeviceID,
            transport: transport,
            clipboard: clipboard,
            transfers: transfers,
            policy: policy
        )
    }

    func tearDown() {
        try? FileManager.default.removeItem(at: root)
    }

    func stage(_ payload: Data, named name: String) throws -> URL {
        try FileManager.default.createDirectory(at: paths.stagingDirectory, withIntermediateDirectories: true)
        let url = paths.stagingDirectory.appending(path: name, directoryHint: .notDirectory)
        try payload.write(to: url, options: .atomic)
        return url
    }

    func localClip(
        _ representations: [ClipRepresentation],
        blobSources: [TransferID: URL] = [:],
        origin: DeviceID = ClipRouterEnvironment.localDeviceID
    ) -> LocalClip {
        LocalClip(
            origin: origin,
            snapshot: PasteboardSnapshot(
                changeCount: 1,
                representations: representations,
                blobSources: blobSources
            )
        )
    }

    func incomingClip(
        _ representations: [ClipRepresentation],
        origin: DeviceID = ClipRouterEnvironment.peerDeviceID
    ) -> ClipMessage {
        ClipMessage(
            id: ClipID(),
            timestampMilliseconds: LocalClip.currentTimestamp(),
            origin: origin,
            hash: ClipCanonicalHash.hexDigest(for: representations),
            representations: representations
        )
    }

    static func policy(send: ClipTypeFlags, receive: ClipTypeFlags, paused: Bool = false) -> SyncPolicy {
        SyncPolicy(
            direction: PeerDirectionPolicy(send: send, receive: receive),
            paused: paused,
            maxBlobBytes: SyncoConstants.Limits.defaultMaxBlobBytes
        )
    }
}
