import Foundation
import SyncoCore
import SyncoTransfer
import XCTest
@testable import SyncoSync

final class ClipRouterStreamingTests: XCTestCase {
    func testStreamsBlobRepresentationAfterClipEnvelope() async throws {
        let environment = ClipRouterEnvironment()
        defer { environment.tearDown() }
        let chunkBytes = SyncoConstants.Framing.maxBlobChunkBytes
        let payload = Data(repeating: 0x42, count: chunkBytes + 512)
        let transferID = TransferID()
        let source = try environment.stage(payload, named: "shot.png")
        let measurement = FileMeasurement(data: payload)
        let clip = environment.localClip(
            [
                .image(ClipImageRepresentation(
                    mime: "image/png",
                    name: "shot.png",
                    size: measurement.size,
                    sha256: measurement.sha256,
                    transferID: transferID
                )),
            ],
            blobSources: [transferID: source]
        )
        let event = await environment.router.send(clip)
        let messages = await environment.transport.recordedMessages()
        let starts = await environment.transport.transferStarts()
        let chunks = await environment.transport.recordedChunks()
        let ends = await environment.transport.transferEnds()
        let hashes = await environment.clipboard.recordedSentHashes()
        XCTAssertEqual(event?.kind, .clipSent)
        XCTAssertEqual(messages.map(\.typeIdentifier), ["clip", "transferStart", "transferEnd"])
        XCTAssertEqual(starts.first?.size, measurement.size)
        XCTAssertEqual(starts.first?.sha256, measurement.sha256)
        XCTAssertNotEqual(starts.first?.transferID, transferID)
        XCTAssertEqual(chunks.map(\.offset), [0, UInt64(chunkBytes)])
        XCTAssertEqual(chunks.first?.transferID, starts.first?.transferID)
        XCTAssertEqual(ends.first?.ok, true)
        XCTAssertEqual(hashes, [clip.hash])
    }

    func testDropsBlobLargerThanPeerAdvertisedLimit() async throws {
        let environment = ClipRouterEnvironment()
        defer { environment.tearDown() }
        _ = await environment.router.handle(
            .caps(CapsMessage(accepts: .all, sends: .all, maxBlob: 512))
        )
        let payload = Data(repeating: 0x43, count: 4096)
        let transferID = TransferID()
        let source = try environment.stage(payload, named: "big.bin")
        let measurement = FileMeasurement(data: payload)
        let clip = environment.localClip(
            [
                .file(ClipFileRepresentation(
                    mime: "application/octet-stream",
                    name: "big.bin",
                    size: measurement.size,
                    sha256: measurement.sha256,
                    transferID: transferID
                )),
            ],
            blobSources: [transferID: source]
        )
        let event = await environment.router.send(clip)
        let messages = await environment.transport.recordedMessages()
        XCTAssertEqual(event?.kind, .clipDropped)
        XCTAssertTrue(messages.isEmpty)
    }
}
