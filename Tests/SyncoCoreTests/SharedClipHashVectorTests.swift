import XCTest
@testable import SyncoCore

final class SharedClipHashVectorTests: XCTestCase {
    private let unitSeparator = "\u{001F}"
    private let recordSeparator = "\u{001E}"
    private let escape = "\u{001D}"

    private let allKindsDigest = "7f94c6d298dcb84c889d004037ba6d1efc3048bdb28637163af92a86183bf81c"
    private let allKindsCanonicalByteCount = 222
    private let textURLPairDigest = "ca36eabccedc7d0156bb0f77a282401f22d07741ed132b9ddd1721ea01bf9a03"
    private let separatorTextDigest = "f9beec0628125ed0edd62ed2fe372cb29e1eab255935c7ffd6905831458d6e1b"
    private let separatorTextCanonical =
        "746578741f68656c6c6f1d1e75726c1d1f68747470733a2f2f6578616d706c652e636f6d1e"
    private let escapeTextDigest = "57940913c675610bcbb7055e74c51933eedade26fafbcb8a5eb85b603440b114"
    private let escapeTextCanonical = "746578741f611d1d621e"
    private let fileSeparatorNameDigest = "03360c1747ee867ec7e4efe89d409d027b40294f02eaabcff0bd5428c1ed832e"
    private let emptyDigest = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

    private let transferIDA = "11112222-3333-4444-5555-666677778888"
    private let transferIDB = "3f2a1b0c-4d5e-6f70-8192-a3b4c5d6e7f8"
    private let imageSHA256 = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
    private let fileSHA256 = "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"

    func testSharedEveryKindRepresentationListDigest() throws {
        let representations = try allKinds()
        XCTAssertEqual(ClipCanonicalHash.hexDigest(for: representations), allKindsDigest)
        XCTAssertEqual(
            ClipCanonicalHash.canonicalBytes(for: representations).count,
            allKindsCanonicalByteCount
        )
    }

    func testSharedTextAndURLPairDigest() {
        XCTAssertEqual(ClipCanonicalHash.hexDigest(for: textURLPair()), textURLPairDigest)
    }

    func testSeparatorsAreEscapedSoContentCannotForgeARepresentationBoundary() {
        XCTAssertEqual(ClipCanonicalHash.hexDigest(for: separatorText()), separatorTextDigest)
        XCTAssertNotEqual(
            ClipCanonicalHash.hexDigest(for: textURLPair()),
            ClipCanonicalHash.hexDigest(for: separatorText())
        )
        XCTAssertEqual(
            HexEncoding.encode(ClipCanonicalHash.canonicalBytes(for: separatorText())),
            separatorTextCanonical
        )
    }

    func testTheEscapeByteItselfIsEscaped() {
        XCTAssertEqual(ClipCanonicalHash.hexDigest(for: escapeText()), escapeTextDigest)
        XCTAssertEqual(
            HexEncoding.encode(ClipCanonicalHash.canonicalBytes(for: escapeText())),
            escapeTextCanonical
        )
    }

    func testSeparatorInsideAFileNameIsEscaped() throws {
        XCTAssertEqual(ClipCanonicalHash.hexDigest(for: try fileSeparatorName()), fileSeparatorNameDigest)
    }

    func testSharedEmptyRepresentationListDigest() {
        XCTAssertEqual(ClipCanonicalHash.hexDigest(for: []), emptyDigest)
    }

    private func allKinds() throws -> [ClipRepresentation] {
        [
            .text("hello"),
            .html("<b>hello</b>"),
            .rtf(Data([0x7B, 0x5C, 0x72, 0x74, 0x66, 0x31, 0x7D])),
            .url(ClipURLRepresentation(url: "https://example.com/a?b=c", title: "Example")),
            .image(ClipImageRepresentation(
                mime: "image/png",
                name: "shot.png",
                size: 91_234,
                sha256: imageSHA256,
                transferID: try transferID(transferIDA)
            )),
            .file(ClipFileRepresentation(
                mime: "text/plain",
                name: "notes.txt",
                size: 12,
                sha256: fileSHA256,
                transferID: try transferID(transferIDB),
                rel: "docs/notes.txt"
            )),
        ]
    }

    private func textURLPair() -> [ClipRepresentation] {
        [.text("hello"), .url(ClipURLRepresentation(url: "https://example.com"))]
    }

    private func separatorText() -> [ClipRepresentation] {
        [.text("hello\(recordSeparator)url\(unitSeparator)https://example.com")]
    }

    private func escapeText() -> [ClipRepresentation] {
        [.text("a\(escape)b")]
    }

    private func fileSeparatorName() throws -> [ClipRepresentation] {
        [.file(ClipFileRepresentation(
            mime: "text/plain",
            name: "a\(unitSeparator)b",
            size: 1,
            sha256: "0f1e2d",
            transferID: try transferID(transferIDA)
        ))]
    }

    private func transferID(_ text: String) throws -> TransferID {
        try XCTUnwrap(TransferID(parsing: text))
    }
}
