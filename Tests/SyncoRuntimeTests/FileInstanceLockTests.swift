import Foundation
import XCTest

@testable import SyncoRuntime

final class FileInstanceLockTests: XCTestCase {
    private var location: InstanceLockLocation!

    override func setUpWithError() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: "SyncoRuntimeTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        location = InstanceLockLocation(
            fileURL: directory.appending(path: "instance.lock", directoryHint: .notDirectory)
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: location.directoryURL)
        location = nil
    }

    func testFirstLaunchAcquiresTheLock() {
        let lock = makeLock()
        defer { lock.release() }
        XCTAssertEqual(lock.acquire(), .acquired)
    }

    func testSecondLaunchIsRefusedWhileTheFirstHoldsTheLock() {
        let owner = ProcessInfo.processInfo.processIdentifier
        let first = makeLock()
        defer { first.release() }
        XCTAssertEqual(first.acquire(), .acquired)

        let second = makeLock(runningPIDs: [owner])
        XCTAssertEqual(second.acquire(), .alreadyRunning(pid: owner))
    }

    func testRefusalReportsNoOwnerWhenTheRecordedPIDIsNotRunning() {
        let first = makeLock()
        defer { first.release() }
        XCTAssertEqual(first.acquire(), .acquired)

        let second = makeLock()
        XCTAssertEqual(second.acquire(), .alreadyRunning(pid: nil))
    }

    func testAcquireIsIdempotentForTheHolder() {
        let lock = makeLock()
        defer { lock.release() }
        XCTAssertEqual(lock.acquire(), .acquired)
        XCTAssertEqual(lock.acquire(), .acquired)
    }

    func testReleasingLetsTheNextLaunchThrough() {
        let first = makeLock()
        XCTAssertEqual(first.acquire(), .acquired)
        first.release()

        let second = makeLock()
        defer { second.release() }
        XCTAssertEqual(second.acquire(), .acquired)
    }

    func testALockFileLeftByACrashedProcessDoesNotBlockLaunch() throws {
        try FileManager.default.createDirectory(
            at: location.directoryURL,
            withIntermediateDirectories: true
        )
        try Data("999999\n".utf8).write(to: location.fileURL)

        let lock = makeLock()
        defer { lock.release() }
        XCTAssertEqual(lock.acquire(), .acquired)
    }

    func testTheHeldLockRecordsTheOwningPID() throws {
        let lock = makeLock()
        defer { lock.release() }
        XCTAssertEqual(lock.acquire(), .acquired)

        let recorded = try String(contentsOf: location.fileURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(pid_t(recorded), ProcessInfo.processInfo.processIdentifier)
    }

    func testTheDefaultLockPathIsPerUserAndIndependentOfTheBundle() {
        XCTAssertEqual(InstanceLockLocation.default, InstanceLockLocation())
        XCTAssertEqual(
            InstanceLockLocation.default.fileURL.lastPathComponent,
            InstanceLockLocation.fileName
        )
        XCTAssertTrue(
            InstanceLockLocation.default.fileURL
                .path(percentEncoded: false)
                .hasPrefix(NSHomeDirectory())
        )
    }

    private func makeLock(runningPIDs: Set<pid_t> = []) -> FileInstanceLock {
        FileInstanceLock(
            location: location,
            liveness: StubProcessLiveness(runningPIDs: runningPIDs)
        )
    }
}
