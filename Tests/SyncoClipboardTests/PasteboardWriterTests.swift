import AppKit
import XCTest
@testable import SyncoClipboard
@testable import SyncoCore

final class PasteboardWriterTests: XCTestCase {

    private struct Staged {
        let id = TransferID()
        let url: URL
    }

    private var pasteboard: NSPasteboard!
    private var directory: URL!

    override func setUp() {
        super.setUp()
        pasteboard = NSPasteboard(name: NSPasteboard.Name("synco.tests.\(UUID().uuidString)"))
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        pasteboard.releaseGlobally()
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    @MainActor
    func testEveryImageOfAMultiImageClipKeepsItsOwnItem() throws {
        let staged = [
            try stage("one.png", bytes: [0x01]),
            try stage("two.png", bytes: [0x02]),
            try stage("three.png", bytes: [0x03]),
        ]

        PasteboardWriter().apply(
            staged.map(image),
            receivedFiles: received(staged),
            to: pasteboard
        )

        XCTAssertEqual(pasteboard.pasteboardItems?.count, 3)
        XCTAssertEqual(fileURLs(), staged.map(\.url.absoluteString))
        XCTAssertEqual(imageData(), [Data([0x01]), Data([0x02]), Data([0x03])])
    }

    @MainActor
    func testASingleImageStaysInlineWithoutAFileURL() throws {
        let only = try stage("only.png", bytes: [0x09])

        PasteboardWriter().apply(
            [image(only)],
            receivedFiles: received([only]),
            to: pasteboard
        )

        XCTAssertEqual(pasteboard.pasteboardItems?.count, 1)
        XCTAssertTrue(fileURLs().isEmpty)
        XCTAssertEqual(imageData(), [Data([0x09])])
    }

    @MainActor
    func testMixedFilesAndImagesEachGetAnItem() throws {
        let picture = try stage("shot.png", bytes: [0x11])
        let archive = try stage("bundle.zip", bytes: [0x22])

        PasteboardWriter().apply(
            [image(picture), file(archive)],
            receivedFiles: received([picture, archive]),
            to: pasteboard
        )

        XCTAssertEqual(pasteboard.pasteboardItems?.count, 2)
        XCTAssertEqual(fileURLs(), [picture, archive].map(\.url.absoluteString))
    }

    @MainActor
    func testTextTravelsWithTheFirstAttachment() throws {
        let picture = try stage("note.png", bytes: [0x33])
        let archive = try stage("note.zip", bytes: [0x44])

        PasteboardWriter().apply(
            [.text("caption"), image(picture), file(archive)],
            receivedFiles: received([picture, archive]),
            to: pasteboard
        )

        XCTAssertEqual(pasteboard.pasteboardItems?.count, 2)
        XCTAssertEqual(pasteboard.pasteboardItems?.first?.string(forType: .string), "caption")
    }

    private func fileURLs() -> [String] {
        (pasteboard.pasteboardItems ?? []).compactMap { $0.string(forType: .fileURL) }
    }

    private func imageData() -> [Data] {
        let type = PasteboardTypeMapping.imageType(forMIME: "image/png")
        return (pasteboard.pasteboardItems ?? []).compactMap { $0.data(forType: type) }
    }

    private func received(_ staged: [Staged]) -> [TransferID: URL] {
        staged.reduce(into: [:]) { mapping, entry in mapping[entry.id] = entry.url }
    }

    private func stage(_ name: String, bytes: [UInt8]) throws -> Staged {
        let destination = directory.appendingPathComponent(name)
        try Data(bytes).write(to: destination)
        return Staged(url: destination)
    }

    private func image(_ staged: Staged) -> ClipRepresentation {
        .image(
            ClipImageRepresentation(
                mime: "image/png",
                name: staged.url.lastPathComponent,
                size: 1,
                sha256: String(repeating: "a", count: 64),
                transferID: staged.id
            )
        )
    }

    private func file(_ staged: Staged) -> ClipRepresentation {
        .file(
            ClipFileRepresentation(
                mime: "application/zip",
                name: staged.url.lastPathComponent,
                size: 1,
                sha256: String(repeating: "b", count: 64),
                transferID: staged.id
            )
        )
    }
}
