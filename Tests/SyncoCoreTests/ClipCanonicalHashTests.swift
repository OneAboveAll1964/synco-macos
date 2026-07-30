import XCTest
@testable import SyncoCore

final class ClipCanonicalHashTests: XCTestCase {
    private let singleTextDigest = "a62bae66362ed98d8826886c3b955c939e1f499f78553f774b52a9cedfeda24e"
    private let allKindsDigest = "7f94c6d298dcb84c889d004037ba6d1efc3048bdb28637163af92a86183bf81c"

    func testCanonicalBytesLayoutForASingleTextRepresentation() {
        let bytes = ClipCanonicalHash.canonicalBytes(for: [.text("hello")])
        XCTAssertEqual(Array(bytes), Array("text".utf8) + [0x1F] + Array("hello".utf8) + [0x1E])
    }

    func testSingleTextRepresentationDigest() {
        XCTAssertEqual(ClipCanonicalHash.hexDigest(for: [.text("hello")]), singleTextDigest)
    }

    func testEveryRepresentationKindDigest() {
        let representations: [ClipRepresentation] = [
            .text("hello"),
            .html("<b>hello</b>"),
            .rtf(Data([0x7B, 0x5C, 0x72, 0x74, 0x66, 0x31, 0x7D])),
            .url(ClipURLRepresentation(url: "https://example.com/a?b=c", title: "Example")),
            .image(ClipImageRepresentation(
                mime: "image/png",
                name: "shot.png",
                size: 91_234,
                sha256: "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
                transferID: TransferID()
            )),
            .file(ClipFileRepresentation(
                mime: "text/plain",
                name: "notes.txt",
                size: 12,
                sha256: "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae",
                transferID: TransferID(),
                rel: "docs/notes.txt"
            )),
        ]
        XCTAssertEqual(ClipCanonicalHash.canonicalBytes(for: representations).count, 222)
        XCTAssertEqual(ClipCanonicalHash.hexDigest(for: representations), allKindsDigest)
    }

    func testDigestIgnoresFieldsOutsideTheCanonicalForm() {
        let first = ClipImageRepresentation(
            mime: "image/png",
            name: "one.png",
            size: 1,
            sha256: "aa",
            transferID: TransferID()
        )
        let second = ClipImageRepresentation(
            mime: "image/jpeg",
            name: "two.jpg",
            size: 999,
            sha256: "aa",
            transferID: TransferID()
        )
        XCTAssertEqual(
            ClipCanonicalHash.hexDigest(for: [.image(first)]),
            ClipCanonicalHash.hexDigest(for: [.image(second)])
        )
    }

    func testFileDigestDependsOnNameAndDigestOnly() {
        let base = ClipFileRepresentation(
            mime: "text/plain",
            name: "a.txt",
            size: 1,
            sha256: "bb",
            transferID: TransferID()
        )
        let renamed = ClipFileRepresentation(
            mime: "text/plain",
            name: "b.txt",
            size: 1,
            sha256: "bb",
            transferID: TransferID()
        )
        XCTAssertNotEqual(
            ClipCanonicalHash.hexDigest(for: [.file(base)]),
            ClipCanonicalHash.hexDigest(for: [.file(renamed)])
        )
    }

    func testOrderChangesTheDigest() {
        let forward: [ClipRepresentation] = [.text("a"), .html("b")]
        let reversed: [ClipRepresentation] = [.html("b"), .text("a")]
        XCTAssertNotEqual(
            ClipCanonicalHash.hexDigest(for: forward),
            ClipCanonicalHash.hexDigest(for: reversed)
        )
    }

    func testEmptyRepresentationListHashesTheEmptyString() {
        XCTAssertEqual(
            ClipCanonicalHash.hexDigest(for: []),
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
    }
}
