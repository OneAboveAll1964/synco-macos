import XCTest
@testable import SyncoSettings

final class LaunchAtLoginStatusTests: XCTestCase {

    func testOnlyRegisteredStatesReadAsOn() {
        XCTAssertTrue(LaunchAtLogin.Status.enabled.isOn)
        XCTAssertTrue(LaunchAtLogin.Status.requiresApproval.isOn)
        XCTAssertFalse(LaunchAtLogin.Status.disabled.isOn)
        XCTAssertFalse(LaunchAtLogin.Status.unavailable.isOn)
    }

    func testTurningOnIsOnlyRememberedWhenMacOSAgreed() {
        XCTAssertTrue(LaunchAtLogin.Status.enabled.matches(true))
        XCTAssertTrue(LaunchAtLogin.Status.requiresApproval.matches(true))
        XCTAssertFalse(LaunchAtLogin.Status.disabled.matches(true))
        XCTAssertFalse(LaunchAtLogin.Status.unavailable.matches(true))
    }

    func testTurningOffIsOnlyRememberedWhenItActuallyUnregistered() {
        XCTAssertTrue(LaunchAtLogin.Status.disabled.matches(false))
        XCTAssertFalse(LaunchAtLogin.Status.enabled.matches(false))
        XCTAssertFalse(LaunchAtLogin.Status.unavailable.matches(false))
    }
}
