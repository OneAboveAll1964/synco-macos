import XCTest
@testable import SyncoCore
@testable import SyncoSettings
@testable import SyncoSync

final class ShizukuStartTests: XCTestCase {

    func testOnlyStartedCarriesNoReason() {
        XCTAssertNil(ShizukuStartOutcome.started.reason)
        XCTAssertTrue(ShizukuStartOutcome.started.didStart)
        for outcome in [ShizukuStartOutcome.notAllowed, .adbMissing, .noDevice, .failed] {
            XCTAssertFalse(outcome.didStart, outcome.rawValue)
            XCTAssertEqual(outcome.reason, outcome.rawValue)
        }
    }

    func testAMissingAdbIsReportedRatherThanAttempted() async {
        let outcome = await ShizukuStarter(adb: nil).start()

        XCTAssertEqual(outcome, .adbMissing)
    }

    func testLocatorSkipsPathsThatAreNotExecutable() {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .path

        XCTAssertNil(AdbLocator.locate(candidates: [missing]))
    }

    func testLocatorReturnsTheFirstExecutableCandidate() throws {
        let found = try XCTUnwrap(AdbLocator.locate(candidates: ["/bin/sh"]))

        XCTAssertEqual(found.path, "/bin/sh")
    }

    func testCapabilityIsAdvertisedOnlyWhenTheUserAllowsIt() {
        let off = SyncPolicy(direction: .bidirectional, paused: false, maxBlobBytes: 1)
        let on = SyncPolicy(
            direction: .bidirectional,
            paused: false,
            maxBlobBytes: 1,
            allowsAdbShizukuStart: true
        )

        XCTAssertFalse(off.capsMessage.adbShizuku)
        XCTAssertTrue(on.capsMessage.adbShizuku)
    }

    func testARouterWithTheOptionOffAnswersNotAllowed() async throws {
        let environment = ClipRouterEnvironment(policy: .default)

        _ = await environment.router.handle(.shizukuStart(ShizukuStartMessage()))

        let results = await environment.transport.shizukuResults()
        let result = try XCTUnwrap(results.last)
        XCTAssertFalse(result.started)
        XCTAssertEqual(result.reason, "notAllowed")
    }

    func testTheStartCommandIsFixed() {
        XCTAssertEqual(
            ShizukuStarter.startScript,
            "/storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh"
        )
    }
}
