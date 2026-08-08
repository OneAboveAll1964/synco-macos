import Foundation
import XCTest
@testable import SyncoCore

final class MediaFrameTests: XCTestCase {

    func testRoundTripPreservesEveryField() throws {
        let frame = MediaFrame(
            stream: 0,
            flags: MediaFrame.keyframe | MediaFrame.lastFragment,
            seq: 4_294_000_111,
            ptsMicros: 9_123_456_789,
            data: Data([0, 0, 0, 1, 103, 66, 42, 7])
        )

        let decoded = try MediaFrame.decode(frame.encoded())

        XCTAssertEqual(decoded, frame)
        XCTAssertTrue(decoded.isKeyframe)
        XCTAssertTrue(decoded.isLastFragment)
        XCTAssertFalse(decoded.isConfig)
        XCTAssertEqual(decoded.seq, 4_294_000_111)
        XCTAssertEqual(decoded.ptsMicros, 9_123_456_789)
    }

    func testFullSequenceNumberSurvives() throws {
        let frame = MediaFrame(stream: 0, flags: 0, seq: .max, ptsMicros: 0, data: Data())
        XCTAssertEqual(try MediaFrame.decode(frame.encoded()).seq, .max)
    }

    func testHeaderOnlyFrameIsValid() throws {
        let frame = MediaFrame(stream: 1, flags: MediaFrame.config, seq: 7, ptsMicros: 42, data: Data())
        let encoded = frame.encoded()
        XCTAssertEqual(encoded.count, MediaFrame.headerBytes)
        XCTAssertEqual(try MediaFrame.decode(encoded), frame)
    }

    func testShortBodyThrows() {
        XCTAssertThrowsError(try MediaFrame.decode(Data(count: MediaFrame.headerBytes - 1)))
    }

    func testKindByteMatchesTheWireContract() {
        XCTAssertEqual(FrameKind.media.rawValue, 0x03)
        XCTAssertEqual(FramePayload.media(Data([1, 2, 3])).kind, .media)
    }
}
