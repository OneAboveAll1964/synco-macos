import XCTest
@testable import SyncoCore

final class ControlMessageWireFormatTests: XCTestCase {
    func testHelloWireKeys() throws {
        let hello = HelloMessage(
            deviceID: ControlMessageFixtures.localDeviceID,
            displayName: "Mac",
            platform: .macOS,
            ephemeralPublicKey: Data([0x01, 0x02, 0x03])
        )
        let object = try jsonObject(.hello(hello))
        XCTAssertEqual(Set(object.keys), ["t", "v", "did", "dn", "pl", "ePub"])
        XCTAssertEqual(object["v"] as? Int, 1)
        XCTAssertEqual(object["did"] as? String, "abcdefghij234567")
        XCTAssertEqual(object["pl"] as? String, "macos")
        XCTAssertEqual(object["ePub"] as? String, "AQID")
    }

    func testAuthWireKeys() throws {
        XCTAssertEqual(Set(try jsonObject(.auth(ControlMessageFixtures.auth)).keys), ["t", "tag"])
    }

    func testPairRequestWireKeys() throws {
        let object = try jsonObject(.pairRequest(ControlMessageFixtures.pairRequest))
        XCTAssertEqual(Set(object.keys), ["t", "did", "dn", "pl", "sPub", "fp"])
        XCTAssertEqual(object["fp"] as? String, "A1B2-C3D4-E5F6-0718")
    }

    func testPairResponseWireKeys() throws {
        let object = try jsonObject(.pairResponse(ControlMessageFixtures.pairResponse))
        XCTAssertEqual(Set(object.keys), ["t", "accepted", "did", "sPub"])
        XCTAssertEqual(object["accepted"] as? Bool, true)
    }

    func testClipWireKeys() throws {
        let object = try jsonObject(.clip(ControlMessageFixtures.clip))
        XCTAssertEqual(Set(object.keys), ["t", "id", "ts", "origin", "hash", "reps"])
        XCTAssertEqual(object["id"] as? String, "3f2a1b0c-4d5e-6f70-8192-a3b4c5d6e7f8")
        XCTAssertEqual(object["ts"] as? Int64, 1_730_300_000_000)
        XCTAssertEqual(object["origin"] as? String, "zyxwvutsrq765432")
    }

    func testRepresentationWireKeys() throws {
        let object = try jsonObject(.clip(ControlMessageFixtures.clip))
        let reps = try XCTUnwrap(object["reps"] as? [[String: Any]])
        XCTAssertEqual(reps.map { $0["k"] as? String }, ["text", "html", "rtf", "url", "image", "file"])
        XCTAssertEqual(reps[0]["text"] as? String, "hello")
        XCTAssertEqual(reps[1]["html"] as? String, "<b>hello</b>")
        XCTAssertEqual(reps[2]["b64"] as? String, "e1xydGYxfQ==")
        XCTAssertEqual(reps[3]["url"] as? String, "https://example.com/a?b=c")
        XCTAssertEqual(reps[3]["title"] as? String, "Example")
        XCTAssertEqual(Set(reps[4].keys), ["k", "mime", "name", "size", "sha256", "transferId"])
        XCTAssertEqual(reps[4]["transferId"] as? String, "11112222-3333-4444-5555-666677778888")
        XCTAssertNil(reps[4]["rel"])
        XCTAssertEqual(reps[5]["rel"] as? String, "docs/notes.txt")
    }

    func testCapsWireShape() throws {
        let object = try jsonObject(.caps(ControlMessageFixtures.caps))
        XCTAssertEqual(Set(object.keys), ["t", "accepts", "sends", "maxBlob"])
        XCTAssertEqual(object["maxBlob"] as? Int64, SyncoConstants.Limits.defaultMaxBlobBytes)
        let sends = try XCTUnwrap(object["sends"] as? [String: Any])
        XCTAssertEqual(Set(sends.keys), ["text", "image", "file"])
        XCTAssertEqual(sends["file"] as? Bool, false)
    }

    func testPingAndPongWireKeys() throws {
        XCTAssertEqual(Set(try jsonObject(.ping(ControlMessageFixtures.ping)).keys), ["t", "seq"])
        XCTAssertEqual(try jsonObject(.pong(ControlMessageFixtures.pong))["seq"] as? Int, 12)
    }

    func testTransferWireKeys() throws {
        XCTAssertEqual(
            Set(try jsonObject(.transferStart(ControlMessageFixtures.transferStart)).keys),
            ["t", "transferId", "clipId", "name", "mime", "size", "sha256"]
        )
        XCTAssertEqual(
            Set(try jsonObject(.transferEnd(ControlMessageFixtures.transferEnd)).keys),
            ["t", "transferId", "ok"]
        )
        let abort = try jsonObject(.transferAbort(ControlMessageFixtures.transferAbort))
        XCTAssertEqual(Set(abort.keys), ["t", "transferId", "reason"])
        XCTAssertEqual(abort["reason"] as? String, "tooLarge")
    }

    func testAppliedAckCarriesExplicitNullReason() throws {
        let encoded = try SyncoJSON.encode(.ack(ControlMessageFixtures.appliedAck))
        XCTAssertTrue(String(decoding: encoded, as: UTF8.self).contains("\"reason\":null"))
    }

    func testRejectedAckCarriesReason() throws {
        let object = try jsonObject(.ack(ControlMessageFixtures.rejectedAck))
        XCTAssertEqual(Set(object.keys), ["t", "id", "applied", "reason"])
        XCTAssertEqual(object["reason"] as? String, "typeDisabled")
    }

    func testByeWireKeys() throws {
        let object = try jsonObject(.bye(ControlMessageFixtures.bye))
        XCTAssertEqual(Set(object.keys), ["t", "reason"])
        XCTAssertEqual(object["reason"] as? String, "shutdown")
    }

    private func jsonObject(_ message: ControlMessage) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: try SyncoJSON.encode(message)) as? [String: Any])
    }
}
