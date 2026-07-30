import Foundation
import SyncoCore
import XCTest
@testable import SyncoTransport

final class BackoffTests: XCTestCase {
    func testCeilingGrowsExponentiallyAndClampsToTheCap() {
        var backoff = Backoff()
        XCTAssertEqual(backoff.ceilingSeconds, 1)
        _ = backoff.nextDelay()
        XCTAssertEqual(backoff.ceilingSeconds, 2)
        _ = backoff.nextDelay()
        XCTAssertEqual(backoff.ceilingSeconds, 4)
        for _ in 0..<10 {
            _ = backoff.nextDelay()
        }
        XCTAssertEqual(backoff.ceilingSeconds, SyncoConstants.Timing.reconnectBackoffCapSeconds)
    }

    func testFullJitterStaysWithinTheCurrentCeilingAndResets() {
        var backoff = Backoff()
        for _ in 0..<64 {
            let ceiling = backoff.ceilingSeconds
            let delay = backoff.nextDelay()
            XCTAssertGreaterThanOrEqual(delay, .zero)
            XCTAssertLessThanOrEqual(delay, .seconds(ceiling))
        }
        backoff.reset()
        XCTAssertEqual(backoff.attempt, 0)
        XCTAssertEqual(backoff.ceilingSeconds, SyncoConstants.Timing.reconnectBackoffBaseSeconds)
    }
}
