import Foundation
import SyncoCore
import SyncoTransfer
import XCTest
@testable import SyncoSync

final class ClipRouterTransferTests: XCTestCase {
    private let payload = Data(repeating: 0x37, count: 4096)

    func testHoldsClipUntilEveryAnnouncedTransferCompletes() async throws {
        let environment = ClipRouterEnvironment()
        defer { environment.tearDown() }
        let measurement = FileMeasurement(data: payload)
        let transferID = TransferID()
        let clip = environment.incomingClip([
            .image(ClipImageRepresentation(
                mime: "image/png",
                name: "shot.png",
                size: measurement.size,
                sha256: measurement.sha256,
                transferID: transferID
            )),
            .text("caption"),
        ])

        let announced = await environment.router.handle(.clip(clip))
        var applied = await environment.clipboard.appliedClips()
        var acks = await environment.transport.acks()
        XCTAssertNil(announced)
        XCTAssertTrue(applied.isEmpty)
        XCTAssertTrue(acks.isEmpty)

        _ = await environment.router.handle(.transferStart(Self.start(for: clip, measurement: measurement, transferID: transferID)))
        _ = await environment.router.accept(BlobChunk(transferID: transferID, offset: 0, data: payload))
        applied = await environment.clipboard.appliedClips()
        acks = await environment.transport.acks()
        XCTAssertTrue(applied.isEmpty)
        XCTAssertTrue(acks.isEmpty)

        let completed = await environment.router.handle(
            .transferEnd(TransferEndMessage(transferID: transferID, ok: true))
        )
        applied = await environment.clipboard.appliedClips()
        acks = await environment.transport.acks()
        let files = await environment.clipboard.appliedFiles()
        XCTAssertEqual(completed?.kind, .clipReceived)
        XCTAssertEqual(applied.count, 1)
        XCTAssertEqual(applied.first?.representations, clip.representations)
        XCTAssertEqual(acks.first?.applied, true)
        let destination = try XCTUnwrap(files.first?[transferID])
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)))
    }

    func testRejectsClipWhenBlobDigestDoesNotMatch() async throws {
        let environment = ClipRouterEnvironment()
        defer { environment.tearDown() }
        let announcedDigest = FileMeasurement(data: Data(repeating: 0x38, count: payload.count))
        let measurement = FileMeasurement(size: Int64(payload.count), sha256: announcedDigest.sha256)
        let transferID = TransferID()
        let clip = environment.incomingClip([
            .file(ClipFileRepresentation(
                mime: "application/octet-stream",
                name: "blob.bin",
                size: measurement.size,
                sha256: measurement.sha256,
                transferID: transferID
            )),
        ])

        _ = await environment.router.handle(.clip(clip))
        _ = await environment.router.handle(.transferStart(Self.start(for: clip, measurement: measurement, transferID: transferID)))
        _ = await environment.router.accept(BlobChunk(transferID: transferID, offset: 0, data: payload))
        let outcome = await environment.router.handle(
            .transferEnd(TransferEndMessage(transferID: transferID, ok: true))
        )
        let applied = await environment.clipboard.appliedClips()
        let acks = await environment.transport.acks()
        XCTAssertEqual(outcome?.kind, .clipRejected(.hashMismatch))
        XCTAssertTrue(applied.isEmpty)
        XCTAssertEqual(acks.first?.reason, .hashMismatch)
    }

    func testAbortsTransferStartThatNoPendingClipAnnounced() async {
        let environment = ClipRouterEnvironment()
        defer { environment.tearDown() }
        let transferID = TransferID()
        let event = await environment.router.handle(.transferStart(TransferStartMessage(
            transferID: transferID,
            clipID: ClipID(),
            name: "stray.bin",
            mime: "application/octet-stream",
            size: 8,
            sha256: String(repeating: "b", count: 64)
        )))
        let aborts = await environment.transport.transferAborts()
        XCTAssertNil(event)
        XCTAssertEqual(aborts.count, 1)
        XCTAssertEqual(aborts.first?.transferID, transferID)
    }

    private static func start(
        for clip: ClipMessage,
        measurement: FileMeasurement,
        transferID: TransferID
    ) -> TransferStartMessage {
        TransferStartMessage(
            transferID: transferID,
            clipID: clip.id,
            name: "blob.bin",
            mime: "application/octet-stream",
            size: measurement.size,
            sha256: measurement.sha256
        )
    }
}
