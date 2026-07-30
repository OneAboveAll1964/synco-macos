import Foundation
import XCTest

@testable import SyncoRuntime

final class SingleInstanceGuardTests: XCTestCase {
    func testAFreeLockAdmitsTheLaunchSilently() {
        let lock = StubInstanceLock(outcome: .acquired)
        let admission = SingleInstanceGuard(lock: lock).admit()
        XCTAssertTrue(admission.allowsLaunch)
        XCTAssertNil(admission.notice)
        XCTAssertEqual(lock.acquireCount, 1)
    }

    func testAHeldLockRefusesTheLaunchAndNamesTheOwner() {
        let admission = SingleInstanceGuard(lock: StubInstanceLock(outcome: .alreadyRunning(pid: 4321))).admit()
        XCTAssertFalse(admission.allowsLaunch)
        XCTAssertEqual(admission.notice?.contains("pid 4321"), true)
        XCTAssertEqual(admission.notice?.contains("already running"), true)
    }

    func testAHeldLockWithoutAReadableOwnerStillRefusesTheLaunch() {
        let admission = SingleInstanceGuard(lock: StubInstanceLock(outcome: .alreadyRunning(pid: nil))).admit()
        XCTAssertFalse(admission.allowsLaunch)
        XCTAssertEqual(admission.notice?.contains("unidentified"), true)
    }

    func testAnUnusableLockAdmitsTheLaunchButWarns() {
        let admission = SingleInstanceGuard(lock: StubInstanceLock(outcome: .unavailable("read-only file system"))).admit()
        XCTAssertTrue(admission.allowsLaunch)
        XCTAssertEqual(admission.notice?.contains("read-only file system"), true)
    }

    func testRelinquishReleasesTheLock() {
        let lock = StubInstanceLock(outcome: .acquired)
        let guardUnderTest = SingleInstanceGuard(lock: lock)
        XCTAssertTrue(guardUnderTest.admit().allowsLaunch)
        guardUnderTest.relinquish()
        XCTAssertEqual(lock.releaseCount, 1)
    }

    func testEveryRefusalCarriesALineWorthLogging() {
        let refusals = [
            InstanceAdmission.refused(existing: 1),
            InstanceAdmission.refused(existing: nil),
        ]
        for refusal in refusals {
            XCTAssertFalse(refusal.allowsLaunch)
            XCTAssertFalse(refusal.notice?.isEmpty ?? true)
        }
    }
}
