import Foundation
import SyncoCore
import XCTest
@testable import SyncoRemote

final class MediaFrameFragmenterTests: XCTestCase {

    func testASmallPictureIsOneFrameFlaggedLast() {
        let fragmenter = MediaFrameFragmenter(maxFragmentBytes: 1000)
        let picture = EncodedPicture(data: Data(repeating: 7, count: 500), ptsMicros: 42, isKeyframe: true, isConfig: false)

        let frames = fragmenter.fragments(for: picture, seq: 9)

        XCTAssertEqual(frames.count, 1)
        XCTAssertTrue(frames[0].isKeyframe)
        XCTAssertTrue(frames[0].isLastFragment)
        XCTAssertEqual(frames[0].seq, 9)
        XCTAssertEqual(frames[0].ptsMicros, 42)
        XCTAssertEqual(frames[0].data.count, 500)
    }

    func testALargePictureSplitsAndOnlyTheLastIsFlagged() {
        let fragmenter = MediaFrameFragmenter(maxFragmentBytes: 1000)
        let picture = EncodedPicture(data: Data(repeating: 3, count: 2500), ptsMicros: 1, isKeyframe: true, isConfig: false)

        let frames = fragmenter.fragments(for: picture, seq: 4)

        XCTAssertEqual(frames.count, 3)
        XCTAssertEqual(frames.map(\.data.count), [1000, 1000, 500])
        XCTAssertEqual(frames.filter { $0.isLastFragment }.count, 1)
        XCTAssertTrue(frames.last!.isLastFragment)
        XCTAssertTrue(frames.allSatisfy { $0.isKeyframe })
        XCTAssertTrue(frames.allSatisfy { $0.seq == 4 })
    }

    func testReassemblingTheFragmentsRebuildsThePicture() {
        let fragmenter = MediaFrameFragmenter(maxFragmentBytes: 64)
        let original = Data((0..<300).map { UInt8($0 % 251) })
        let picture = EncodedPicture(data: original, ptsMicros: 0, isKeyframe: false, isConfig: false)

        let frames = fragmenter.fragments(for: picture, seq: 1)
        let reassembled = frames.reduce(Data()) { $0 + $1.data }

        XCTAssertEqual(reassembled, original)
    }

    func testEveryFragmentFitsUnderTheFrameCap() {
        let fragmenter = MediaFrameFragmenter()
        let picture = EncodedPicture(data: Data(repeating: 9, count: 5_000_000), ptsMicros: 0, isKeyframe: true, isConfig: false)

        let frames = fragmenter.fragments(for: picture, seq: 1)

        XCTAssertTrue(frames.allSatisfy { $0.encoded().count + 1 <= SyncoConstants.Framing.maxPayloadBytes })
    }

    func testConfigFlagIsCarried() {
        let fragmenter = MediaFrameFragmenter()
        let picture = EncodedPicture(data: Data([1, 2, 3]), ptsMicros: 0, isKeyframe: false, isConfig: true)

        let frames = fragmenter.fragments(for: picture, seq: 1)

        XCTAssertTrue(frames[0].isConfig)
    }
}
