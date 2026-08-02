import XCTest
@testable import SyncoSettings

final class LoginAgentPlistTests: XCTestCase {

    private let executable = URL(fileURLWithPath: "/Applications/Synco.app/Contents/MacOS/Synco")

    func testThePlistPointsAtTheAppBinaryAndRunsAtLogin() throws {
        let data = try LoginAgentPlist.data(executable: executable)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )

        XCTAssertEqual(plist["Label"] as? String, "com.shkomaghdid.synco.macos.login")
        XCTAssertEqual(plist["ProgramArguments"] as? [String], [executable.path])
        XCTAssertEqual(plist["RunAtLoad"] as? Bool, true)
    }

    func testItDoesNotRelaunchTheAppWhenTheUserQuitsIt() {
        let contents = LoginAgentPlist.contents(executable: executable)

        XCTAssertEqual(contents["KeepAlive"] as? Bool, false)
    }

    func testItOnlyLoadsInARealLoginSession() {
        let contents = LoginAgentPlist.contents(executable: executable)

        XCTAssertEqual(contents["LimitLoadToSessionType"] as? String, "Aqua")
    }

    func testThePlistLandsInTheUsersLaunchAgentsFolder() {
        let home = URL(fileURLWithPath: "/Users/example")

        let url = LoginAgentPlist.url(in: LoginAgentPlist.directory(home: home))

        XCTAssertEqual(
            url.path,
            "/Users/example/Library/LaunchAgents/com.shkomaghdid.synco.macos.login.plist"
        )
    }
}
