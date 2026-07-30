import XCTest
@testable import SyncoCore

final class FrameCodecTests: XCTestCase {
    func testEncodeWritesFourByteBigEndianLengthPrefix() throws {
        let payload = Data(repeating: 0x5A, count: 300)
        let frame = try FrameCodec.encode(payload)
        XCTAssertEqual(frame.count, 304)
        XCTAssertEqual(Array(frame.prefix(4)), [0x00, 0x00, 0x01, 0x2C])
        XCTAssertEqual(Data(frame.dropFirst(4)), payload)
    }

    func testEncodeRejectsEmptyPayload() {
        XCTAssertThrowsError(try FrameCodec.encode(Data())) { error in
            XCTAssertEqual(error as? SyncoError, .invalidFrameLength(0))
        }
    }

    func testEncodeRejectsOversizedPayload() {
        let payload = Data(repeating: 0x00, count: SyncoConstants.Framing.maxPayloadBytes + 1)
        XCTAssertThrowsError(try FrameCodec.encode(payload)) { error in
            XCTAssertEqual(error as? SyncoError, .frameTooLarge(UInt32(payload.count)))
        }
    }

    func testDecoderFedOneByteAtATime() throws {
        let first = Data("first frame".utf8)
        let second = Data(repeating: 0x11, count: 1024)
        var stream = try FrameCodec.encode(first)
        stream.append(try FrameCodec.encode(second))
        var decoder = FrameCodec.Decoder()
        var frames: [Data] = []
        for byte in stream {
            frames.append(contentsOf: try decoder.push(CollectionOfOne(byte)))
        }
        XCTAssertEqual(frames, [first, second])
        XCTAssertEqual(decoder.bufferedByteCount, 0)
    }

    func testDecoderYieldsNothingUntilFrameIsComplete() throws {
        let payload = Data("hello world".utf8)
        let frame = try FrameCodec.encode(payload)
        var decoder = FrameCodec.Decoder()
        for byte in frame.dropLast() {
            XCTAssertTrue(try decoder.push(CollectionOfOne(byte)).isEmpty)
        }
        let lastByte = try XCTUnwrap(frame.last)
        XCTAssertEqual(try decoder.push(CollectionOfOne(lastByte)), [payload])
    }

    func testDecoderHandlesMultipleFramesInOneChunk() throws {
        let payloads = (0..<5).map { Data(repeating: UInt8($0), count: 64 * ($0 + 1)) }
        var stream = Data()
        for payload in payloads {
            stream.append(try FrameCodec.encode(payload))
        }
        var decoder = FrameCodec.Decoder()
        XCTAssertEqual(try decoder.push(stream), payloads)
    }

    func testDecoderRejectsOversizedLength() {
        let header = Data([0x00, 0x20, 0x00, 0x01])
        var decoder = FrameCodec.Decoder()
        XCTAssertThrowsError(try decoder.push(header)) { error in
            XCTAssertEqual(error as? SyncoError, .frameTooLarge(2_097_153))
        }
    }

    func testDecoderRejectsOversizedLengthBeforeBodyArrives() {
        let header = Data([0x00, 0x10, 0x00, 0x01])
        var decoder = FrameCodec.Decoder()
        XCTAssertThrowsError(try decoder.push(header)) { error in
            XCTAssertEqual(error as? SyncoError, .frameTooLarge(UInt32(SyncoConstants.Framing.maxPayloadBytes + 1)))
        }
    }

    func testDecoderRejectsZeroLength() {
        var decoder = FrameCodec.Decoder()
        XCTAssertThrowsError(try decoder.push(Data([0x00, 0x00, 0x00, 0x00]))) { error in
            XCTAssertEqual(error as? SyncoError, .invalidFrameLength(0))
        }
    }

    func testMaximumSizedPayloadIsAccepted() throws {
        let payload = Data(repeating: 0x7F, count: SyncoConstants.Framing.maxPayloadBytes)
        var decoder = FrameCodec.Decoder()
        XCTAssertEqual(try decoder.push(try FrameCodec.encode(payload)), [payload])
    }

    func testPayloadKindRoundTrip() throws {
        let payload = FramePayload.control(Data("{}".utf8))
        let frame = try FrameCodec.encode(payload)
        var decoder = FrameCodec.Decoder()
        let frames = try decoder.push(frame)
        XCTAssertEqual(try FramePayload.decode(frames[0]), payload)
    }

    func testUnknownKindIsReported() {
        XCTAssertThrowsError(try FramePayload.decode(Data([0x09, 0x01]))) { error in
            XCTAssertEqual(error as? SyncoError, .unknownFrameKind(0x09))
        }
    }

    func testEmptyPayloadIsReported() {
        XCTAssertThrowsError(try FramePayload.decode(Data())) { error in
            XCTAssertEqual(error as? SyncoError, .emptyFramePayload)
        }
    }
}
