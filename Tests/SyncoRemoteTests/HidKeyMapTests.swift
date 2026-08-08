import CoreGraphics
import XCTest
@testable import SyncoRemote

final class HidKeyMapTests: XCTestCase {

    func testLettersMapToAnsiKeys() {
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x04), 0)
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x06), 8)
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x1D), 6)
    }

    func testEditingKeysMap() {
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x28), 36)
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x2A), 51)
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x29), 53)
    }

    func testArrowsMap() {
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x4F), 124)
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x50), 123)
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x51), 125)
        XCTAssertEqual(HidKeyMap.virtualKey(forUsage: 0x52), 126)
    }

    func testUnknownUsageHasNoKey() {
        XCTAssertNil(HidKeyMap.virtualKey(forUsage: 0xFF))
        XCTAssertNil(HidKeyMap.virtualKey(forUsage: 0))
    }

    func testModifierBitsBecomeEventFlags() {
        XCTAssertEqual(HidKeyMap.flags(forModifiers: 0), [])
        XCTAssertTrue(HidKeyMap.flags(forModifiers: 0x08).contains(.maskCommand))
        XCTAssertTrue(HidKeyMap.flags(forModifiers: 0x01).contains(.maskShift))
        let all = HidKeyMap.flags(forModifiers: 0x0F)
        XCTAssertTrue(all.contains(.maskControl))
        XCTAssertTrue(all.contains(.maskAlternate))
    }

    func testEveryMappedUsageIsUnique() {
        let usages = (0x04...0x52).compactMap { HidKeyMap.virtualKey(forUsage: $0) }
        XCTAssertEqual(usages.count, Set(usages).count)
    }
}
