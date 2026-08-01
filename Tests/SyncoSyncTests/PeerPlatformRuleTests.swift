import XCTest
@testable import SyncoCore
@testable import SyncoSync

final class PeerPlatformRuleTests: XCTestCase {

    func testAMacIgnoresOtherMacs() {
        XCTAssertFalse(PeerPlatformRule.pairs(.macOS, .macOS))
    }

    func testAPhoneIgnoresOtherPhones() {
        XCTAssertFalse(PeerPlatformRule.pairs(.android, .android))
    }

    func testTheTwoPlatformsStillPairWithEachOther() {
        XCTAssertTrue(PeerPlatformRule.pairs(.macOS, .android))
        XCTAssertTrue(PeerPlatformRule.pairs(.android, .macOS))
    }
}
