import CoreGraphics
import XCTest
@testable import SyncoRemote

final class RemotePointerMapperTests: XCTestCase {

    private let mapper = RemotePointerMapper(
        bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080)
    )

    func testCornersMapToTheDisplayEdges() {
        XCTAssertEqual(mapper.point(normalizedX: 0, normalizedY: 0), CGPoint(x: 0, y: 0))
        XCTAssertEqual(mapper.point(normalizedX: 1, normalizedY: 1), CGPoint(x: 1920, y: 1080))
        XCTAssertEqual(mapper.point(normalizedX: 0.5, normalizedY: 0.5), CGPoint(x: 960, y: 540))
    }

    func testOutOfRangeNormalsAreClamped() {
        XCTAssertEqual(mapper.point(normalizedX: 1.5, normalizedY: -0.2), CGPoint(x: 1920, y: 0))
    }

    func testAdvanceStaysInsideTheDisplay() {
        let start = CGPoint(x: 1900, y: 1070)
        let moved = mapper.advance(from: start, byPixelsX: 100, byPixelsY: 100)
        XCTAssertEqual(moved, CGPoint(x: 1920, y: 1080))
    }

    func testAnOffsetDisplayKeepsItsOrigin() {
        let offset = RemotePointerMapper(bounds: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        XCTAssertEqual(offset.point(normalizedX: 0, normalizedY: 0), CGPoint(x: 1920, y: 0))
        XCTAssertEqual(offset.point(normalizedX: 1, normalizedY: 1), CGPoint(x: 3840, y: 1080))
    }
}
