import XCTest
@testable import SyncoCore

final class ControlMessageTests: XCTestCase {
    func testEveryMessageTypeSurvivesJSONRoundTrip() throws {
        for message in ControlMessageFixtures.all {
            let encoded = try SyncoJSON.encode(message)
            XCTAssertEqual(try SyncoJSON.decode(encoded), message, message.typeIdentifier)
        }
    }

    func testEveryDeclaredTypeIsCovered() {
        let covered = Set(ControlMessageFixtures.all.compactMap(\.type))
        XCTAssertEqual(covered, Set(ControlMessageType.allCases))
    }

    func testDiscriminatorIsWrittenForEveryMessage() throws {
        for message in ControlMessageFixtures.all {
            let encoded = try SyncoJSON.encode(message)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            XCTAssertEqual(object["t"] as? String, message.typeIdentifier)
        }
    }

    func testHandshakeMessagesAreMarkedPlaintext() {
        XCTAssertTrue(ControlMessageType.hello.isPlaintextHandshake)
        XCTAssertTrue(ControlMessageType.auth.isPlaintextHandshake)
        XCTAssertTrue(ControlMessageType.pairRequest.isPlaintextHandshake)
        XCTAssertTrue(ControlMessageType.pairResponse.isPlaintextHandshake)
        XCTAssertFalse(ControlMessageType.clip.isPlaintextHandshake)
        XCTAssertFalse(ControlMessageType.caps.isPlaintextHandshake)
    }

    func testUnknownMessageTypeDecodesToUnknown() throws {
        let payload = Data("{\"t\":\"quantumClip\",\"future\":[1,2,3]}".utf8)
        XCTAssertEqual(try SyncoJSON.decode(payload), .unknown(type: "quantumClip"))
    }

    func testUnknownMessageTypeIsPreservedOnReEncode() throws {
        let encoded = try SyncoJSON.encode(.unknown(type: "quantumClip"))
        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), "{\"t\":\"quantumClip\"}")
    }

    func testUnknownFieldsOnKnownMessageAreIgnored() throws {
        let payload = Data("{\"t\":\"ping\",\"seq\":7,\"jitter\":42}".utf8)
        XCTAssertEqual(try SyncoJSON.decode(payload), .ping(PingMessage(seq: 7)))
    }

    func testUnknownCloseReasonDecodesWithoutThrowing() throws {
        let payload = Data("{\"t\":\"bye\",\"reason\":\"solarFlare\"}".utf8)
        XCTAssertEqual(try SyncoJSON.decode(payload), .bye(ByeMessage(reason: CloseReason(rawValue: "solarFlare"))))
    }

    func testMissingDiscriminatorIsRejected() {
        XCTAssertThrowsError(try SyncoJSON.decode(Data("{\"seq\":1}".utf8)))
    }

    func testMalformedBodyOnKnownTypeIsRejected() {
        XCTAssertThrowsError(try SyncoJSON.decode(Data("{\"t\":\"ping\"}".utf8)))
        XCTAssertThrowsError(try SyncoJSON.decode(Data("{\"t\":\"hello\",\"did\":\"short\"}".utf8)))
    }

    func testControlFrameRoundTrip() throws {
        let message = ControlMessage.ping(ControlMessageFixtures.ping)
        let payload = try SyncoJSON.controlFrame(message)
        XCTAssertEqual(payload.kind, .control)
        XCTAssertEqual(try SyncoJSON.controlMessage(from: payload), message)
    }

    func testBlobFrameIsNotDecodedAsControl() {
        let payload = FramePayload.blobChunk(Data("{}".utf8))
        XCTAssertThrowsError(try SyncoJSON.controlMessage(from: payload))
    }

    func testClipReportsItsBlobTransfers() {
        XCTAssertEqual(
            ControlMessageFixtures.clip.blobTransferIDs,
            [ControlMessageFixtures.transferID, ControlMessageFixtures.transferID]
        )
    }

    func testClipHashIsTheCanonicalDigestOfItsRepresentations() {
        XCTAssertEqual(
            ControlMessageFixtures.clip.hash,
            ClipCanonicalHash.hexDigest(for: ControlMessageFixtures.representations)
        )
    }

    func testCloseReasonsFromSpecificationAreStable() {
        XCTAssertEqual(
            CloseReason.allKnown.map(\.rawValue),
            [
                "versionMismatch", "selfConnection", "unknownKey", "didMismatch",
                "badHandshake", "badAuth", "frameTooLarge", "replay",
                "timeout", "duplicateSession", "shutdown", "unpaired",
            ]
        )
    }

    func testRejectionReasonsFromSpecificationAreStable() {
        XCTAssertEqual(
            ClipRejectionReason.allKnown.map(\.rawValue),
            ["typeDisabled", "receiveDisabled", "tooLarge", "hashMismatch", "userCancelled"]
        )
    }

    func testTypeFlagsFollowTheRepresentationKind() {
        let textOnly = ClipTypeFlags(text: true, image: false, file: false)
        XCTAssertTrue(ClipRepresentationKind.allCases.filter(textOnly.allows).allSatisfy(\.isInline))
        XCTAssertTrue(ClipTypeFlags.all.allows(.file))
        XCTAssertTrue(ClipTypeFlags.none.allowsNothing)
    }
}
