import Foundation
import XCTest

@testable import SyncoClipboard
@testable import SyncoCore

final class PasteboardReaderTests: XCTestCase {

    private let reader = PasteboardReader()

    func testAFinderFileCopyDoesNotCarryItsNameAsText() throws {
        let file = try stagedFile(named: "quarterly.pdf", bytes: 2048)
        defer { try? FileManager.default.removeItem(at: file) }

        let snapshot = reader.read(
            PasteboardCapture(changeCount: 1, fileURLs: [file], text: "quarterly.pdf")
        )

        XCTAssertEqual(snapshot.representations.count, 1)
        XCTAssertNil(firstText(in: snapshot))
        XCTAssertEqual(fileNames(in: snapshot), ["quarterly.pdf"])
    }

    func testSeveralFilesEachBecomeTheirOwnRepresentation() throws {
        let first = try stagedFile(named: "a.txt", bytes: 16)
        let second = try stagedFile(named: "b.txt", bytes: 32)
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }

        let snapshot = reader.read(
            PasteboardCapture(changeCount: 2, fileURLs: [first, second], text: "2 items")
        )

        XCTAssertEqual(Set(fileNames(in: snapshot)), ["a.txt", "b.txt"])
        XCTAssertNil(firstText(in: snapshot))
    }

    func testPlainTextIsStillCapturedWhenNoFilesArePresent() {
        let snapshot = reader.read(PasteboardCapture(changeCount: 3, text: "hello"))
        XCTAssertEqual(firstText(in: snapshot), "hello")
    }

    func testAURLIsStillCapturedWhenNoFilesArePresent() {
        let snapshot = reader.read(
            PasteboardCapture(changeCount: 4, text: "Example", urlString: "https://example.com")
        )
        XCTAssertTrue(snapshot.representations.contains { representation in
            if case .url = representation { return true }
            return false
        })
    }

    private func firstText(in snapshot: PasteboardSnapshot) -> String? {
        for representation in snapshot.representations {
            if case let .text(value) = representation { return value }
        }
        return nil
    }

    private func fileNames(in snapshot: PasteboardSnapshot) -> [String] {
        snapshot.representations.compactMap { representation in
            if case let .file(file) = representation { return file.name }
            return nil
        }
    }

    private func stagedFile(named name: String, bytes: Int) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("synco-reader-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try Data(repeating: 0x41, count: bytes).write(to: url)
        return url
    }
}
