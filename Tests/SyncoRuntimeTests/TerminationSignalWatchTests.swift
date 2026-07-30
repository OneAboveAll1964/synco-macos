import Foundation
import XCTest

@testable import SyncoRuntime

@MainActor
final class TerminationSignalWatchTests: XCTestCase {
    func testCtrlCAndTheUsualKillSignalsAreWatched() {
        XCTAssertEqual(Set(TerminationSignalWatch.watched), [SIGINT, SIGTERM, SIGHUP])
    }

    func testNoWatchedSignalWouldKillTheProcessBeforeTeardownRuns() {
        for number in TerminationSignalWatch.watched {
            XCTAssertNotEqual(number, SIGKILL)
            XCTAssertNotEqual(number, SIGSTOP)
        }
    }
}
