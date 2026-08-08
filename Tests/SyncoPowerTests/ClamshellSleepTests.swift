import XCTest
@testable import SyncoPower

final class ClamshellSleepTests: XCTestCase {

    func testParsesDisabledFlag() {
        let output = """
        System-wide power settings:
         SleepDisabled\t\t1
        Currently in use:
         standby              1
        """
        XCTAssertEqual(ClamshellSleep.parse(output), true)
    }

    func testParsesEnabledFlag() {
        XCTAssertEqual(ClamshellSleep.parse(" SleepDisabled\t\t0\n"), false)
    }

    func testMissingFlagIsUnknown() {
        XCTAssertNil(ClamshellSleep.parse("Currently in use:\n sleep 1\n"))
    }

    func testIgnoresUnrelatedLinesWithTwoFields() {
        let output = " standby              1\n SleepDisabled\t\t1\n"
        XCTAssertEqual(ClamshellSleep.parse(output), true)
    }

    func testScriptTogglesPmset() {
        XCTAssertTrue(ClamshellSleep.script(disablingSleep: true).contains("disablesleep 1"))
        XCTAssertTrue(ClamshellSleep.script(disablingSleep: false).contains("disablesleep 0"))
        XCTAssertTrue(ClamshellSleep.script(disablingSleep: true).contains("administrator privileges"))
    }
}
