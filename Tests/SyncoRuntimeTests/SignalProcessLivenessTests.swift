import Foundation
import XCTest

@testable import SyncoRuntime

final class SignalProcessLivenessTests: XCTestCase {
    private let liveness = SignalProcessLiveness()

    func testThisProcessIsRunning() {
        XCTAssertTrue(liveness.isRunning(ProcessInfo.processInfo.processIdentifier))
    }

    func testLaunchdIsRunningEvenThoughItBelongsToAnotherUser() {
        XCTAssertTrue(liveness.isRunning(1))
    }

    func testAPIDBeyondTheSystemRangeIsNotRunning() {
        XCTAssertFalse(liveness.isRunning(999_999))
    }

    func testNonPositivePIDsAreNeverTreatedAsRunning() {
        XCTAssertFalse(liveness.isRunning(0))
        XCTAssertFalse(liveness.isRunning(-1))
    }
}
