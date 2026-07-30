import Foundation
import XCTest

@testable import SyncoRuntime

final class BundleEnvironmentTests: XCTestCase {
    func testABundledLaunchIsSilentAtStartup() {
        let bundled = BundleEnvironment(bundleIdentifier: "app.synco", pathExtension: "app")
        XCTAssertTrue(bundled.isBundled)
        XCTAssertNil(bundled.startupNotice)
    }

    func testABareBinaryIsReportedAsUnbundled() {
        let bare = BundleEnvironment(bundleIdentifier: nil, pathExtension: "")
        XCTAssertFalse(bare.isBundled)
        XCTAssertNotNil(bare.startupNotice)
    }

    func testABinaryInsideANonAppDirectoryIsAlsoUnbundled() {
        let disguised = BundleEnvironment(bundleIdentifier: "app.synco", pathExtension: "build")
        XCTAssertFalse(disguised.isBundled)
        XCTAssertNotNil(disguised.startupNotice)
    }

    func testTheUnbundledNoticeNamesTheLimitAndTheFix() throws {
        let notice = try XCTUnwrap(BundleEnvironment(bundleIdentifier: nil, pathExtension: "").startupNotice)
        XCTAssertTrue(notice.contains("local network"))
        XCTAssertTrue(notice.contains("launch at login"))
        XCTAssertTrue(notice.contains("package-app.sh"))
    }

    func testTheUnbundledNoticeSaysSyncStillRunsForDevelopment() throws {
        let notice = try XCTUnwrap(BundleEnvironment(bundleIdentifier: nil, pathExtension: "").startupNotice)
        XCTAssertTrue(notice.contains("still run"))
        XCTAssertTrue(notice.contains("development"))
    }

    func testTheRunningProcessReportsAConsistentEnvironment() {
        let current = BundleEnvironment.current
        XCTAssertEqual(current.startupNotice == nil, current.isBundled)
    }
}
