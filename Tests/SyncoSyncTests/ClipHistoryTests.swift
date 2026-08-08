import Foundation
import SyncoCore
import XCTest
@testable import SyncoSync

final class ClipHistoryTests: XCTestCase {

    private func temporaryStore() -> ClipHistoryStore {
        ClipHistoryStore(
            directory: FileManager.default.temporaryDirectory
                .appendingPathComponent("synco-history-\(UUID().uuidString)")
        )
    }

    func testAURLBeatsTextAndBlankTextIsIgnored() {
        XCTAssertEqual(
            ClipHistoryStore.entry(
                for: [.text("Example"), .url(ClipURLRepresentation(url: "https://example.com"))],
                fromPeer: false
            )?.text,
            "https://example.com"
        )
        XCTAssertNil(ClipHistoryStore.entry(for: [.text("   \n")], fromPeer: false))
        XCTAssertNil(ClipHistoryStore.entry(for: [], fromPeer: true))
    }

    func testRecordingDeduplicatesAndCaps() async {
        let store = temporaryStore()

        for index in 0..<40 {
            await store.record(representations: [.text("clip \(index)")], fromPeer: false)
        }
        await store.record(representations: [.text("clip 39")], fromPeer: true)

        let entries = await store.entries()
        XCTAssertEqual(entries.count, ClipHistoryStore.maxEntries)
        XCTAssertEqual(entries.first?.text, "clip 39")
        XCTAssertEqual(entries.filter { $0.text == "clip 39" }.count, 1)
        XCTAssertTrue(entries.first?.fromPeer == true)
    }

    func testHistorySurvivesAReload() async {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("synco-history-\(UUID().uuidString)")
        let first = ClipHistoryStore(directory: directory)
        await first.record(representations: [.text("persist me")], fromPeer: false)

        let second = ClipHistoryStore(directory: directory)
        let entries = await second.entries()

        XCTAssertEqual(entries.first?.text, "persist me")
    }
}
