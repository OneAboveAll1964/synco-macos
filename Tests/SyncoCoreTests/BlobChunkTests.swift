import XCTest
@testable import SyncoCore

final class BlobChunkTests: XCTestCase {
    private let transferID = TransferID(uuid: UUID(uuidString: "3F2A1B0C-4D5E-6F70-8192-A3B4C5D6E7F8")!)

    func testEncodedLayout() throws {
        let chunk = BlobChunk(transferID: transferID, offset: 0x0102030405060708, data: Data([0xAA, 0xBB]))
        let body = try chunk.encodedBody()
        XCTAssertEqual(body.count, 26)
        XCTAssertEqual(
            Array(body.prefix(16)),
            [0x3F, 0x2A, 0x1B, 0x0C, 0x4D, 0x5E, 0x6F, 0x70, 0x81, 0x92, 0xA3, 0xB4, 0xC5, 0xD6, 0xE7, 0xF8]
        )
        XCTAssertEqual(Array(body[16..<24]), [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
        XCTAssertEqual(Data(body.dropFirst(24)), Data([0xAA, 0xBB]))
    }

    func testRoundTrip() throws {
        let payload = Data((0..<5000).map { UInt8(($0 * 7) % 256) })
        let chunk = BlobChunk(transferID: transferID, offset: 262_144, data: payload)
        let decoded = try BlobChunk.decode(body: try chunk.encodedBody())
        XCTAssertEqual(decoded, chunk)
        XCTAssertEqual(decoded.transferID.stringValue, "3f2a1b0c-4d5e-6f70-8192-a3b4c5d6e7f8")
        XCTAssertEqual(decoded.endOffset, 267_144)
    }

    func testRoundTripThroughFramePayload() throws {
        let chunk = BlobChunk(transferID: transferID, offset: 42, data: Data("blob".utf8))
        let payload = try chunk.framePayload()
        XCTAssertEqual(payload.kind, .blobChunk)
        XCTAssertEqual(try BlobChunk.decode(body: payload.body), chunk)
    }

    func testEmptyChunkDataIsPreserved() throws {
        let chunk = BlobChunk(transferID: transferID, offset: 9, data: Data())
        XCTAssertEqual(try BlobChunk.decode(body: try chunk.encodedBody()), chunk)
    }

    func testShortBodyIsRejected() {
        XCTAssertThrowsError(try BlobChunk.decode(body: Data(repeating: 0, count: 23))) { error in
            XCTAssertEqual(error as? SyncoError, .malformedBlobChunk)
        }
    }

    func testOversizedChunkIsRejected() {
        let payload = Data(repeating: 0, count: SyncoConstants.Framing.maxBlobChunkBytes + 1)
        let chunk = BlobChunk(transferID: transferID, offset: 0, data: payload)
        XCTAssertThrowsError(try chunk.encodedBody()) { error in
            XCTAssertEqual(error as? SyncoError, .blobChunkTooLarge(payload.count))
        }
    }

    func testMaximumChunkIsAccepted() throws {
        let payload = Data(repeating: 0x33, count: SyncoConstants.Framing.maxBlobChunkBytes)
        let chunk = BlobChunk(transferID: transferID, offset: 0, data: payload)
        XCTAssertEqual(try BlobChunk.decode(body: try chunk.encodedBody()), chunk)
    }

    func testTransferIDRawBytesRoundTrip() throws {
        let restored = try XCTUnwrap(TransferID(rawBytes: transferID.rawBytes))
        XCTAssertEqual(restored, transferID)
    }
}
