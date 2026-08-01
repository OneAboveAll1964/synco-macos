import XCTest
@testable import SyncoCore
@testable import SyncoSettings
@testable import SyncoSync

final class ShizukuStartTests: XCTestCase {

    func testOnlyStartedCarriesNoReason() {
        XCTAssertNil(ShizukuStartOutcome.started.reason)
        XCTAssertTrue(ShizukuStartOutcome.started.didStart)
        for outcome in [
            ShizukuStartOutcome.notAllowed, .adbMissing, .noDevice, .notInstalled, .noStarter, .failed,
        ] {
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

    func testTheStarterOutputIsReadCorrectly() {
        XCTAssertEqual(
            ShizukuStarter.outcome(of: "info: starter begin\ninfo: shizuku_starter exit with 0\n"),
            .started
        )
        XCTAssertEqual(ShizukuStarter.outcome(of: "synco-status: not-installed"), .notInstalled)
        XCTAssertEqual(ShizukuStarter.outcome(of: "synco-status: no-starter"), .noStarter)
        XCTAssertEqual(ShizukuStarter.outcome(of: "info: shizuku_starter exit with 1"), .failed)
        XCTAssertEqual(ShizukuStarter.outcome(of: ""), .failed)
    }

    func testDeviceSerialsAreParsedSoASingleAdbCallIsNeverAmbiguous() {
        let listing = """
        List of devices attached
        R5CY20VXXYA\tdevice
        emulator-5554\tdevice
        ZY22HQ8LMN\tunauthorized
        ZY99OFFLINE\toffline

        """

        XCTAssertEqual(AdbDevices.serials(in: listing), ["R5CY20VXXYA", "emulator-5554"])
        XCTAssertEqual(AdbDevices.serials(in: "List of devices attached\n\n"), [])
    }

    func testTheMostInformativeOutcomeWinsAcrossDevices() {
        XCTAssertEqual(ShizukuStarter.preferred(.failed, .notInstalled), .notInstalled)
        XCTAssertEqual(ShizukuStarter.preferred(.notInstalled, .noStarter), .noStarter)
        XCTAssertEqual(ShizukuStarter.preferred(.noStarter, .failed), .noStarter)
        XCTAssertEqual(ShizukuStarter.preferred(.notInstalled, .started), .started)
    }

    func testTheScriptDiscoversTheApkRatherThanHardCodingIt() {
        let shell = ShizukuStartScript.shell

        XCTAssertTrue(shell.contains("pm path moe.shizuku.privileged.api"))
        XCTAssertTrue(shell.contains("libshizuku.so"))
        XCTAssertTrue(shell.contains("arm64"))
        XCTAssertTrue(shell.contains(ShizukuStartScript.legacyPath))
        XCTAssertFalse(shell.contains("~~"))
    }
}
