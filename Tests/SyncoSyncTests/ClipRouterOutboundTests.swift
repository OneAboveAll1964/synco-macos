import Foundation
import SyncoCore
import SyncoTransfer
import XCTest
@testable import SyncoSync

final class ClipRouterOutboundTests: XCTestCase {
    func testDropsClipWhenSendPolicyDisablesEveryRepresentation() async {
        let environment = ClipRouterEnvironment(
            policy: ClipRouterEnvironment.policy(send: .none, receive: .all)
        )
        defer { environment.tearDown() }
        let event = await environment.router.send(environment.localClip([.text("hello")]))
        let messages = await environment.transport.recordedMessages()
        let hashes = await environment.clipboard.recordedSentHashes()
        XCTAssertEqual(event?.kind, .clipDropped)
        XCTAssertTrue(messages.isEmpty)
        XCTAssertTrue(hashes.isEmpty)
    }

    func testPausedPolicyDropsClip() async {
        let environment = ClipRouterEnvironment(
            policy: ClipRouterEnvironment.policy(send: .all, receive: .all, paused: true)
        )
        defer { environment.tearDown() }
        let event = await environment.router.send(environment.localClip([.text("hello")]))
        let messages = await environment.transport.recordedMessages()
        XCTAssertEqual(event?.kind, .clipDropped)
        XCTAssertTrue(messages.isEmpty)
    }

    func testStripsRepresentationsDisabledByType() async throws {
        let environment = ClipRouterEnvironment(
            policy: ClipRouterEnvironment.policy(
                send: ClipTypeFlags(text: true, image: false, file: false),
                receive: .all
            )
        )
        defer { environment.tearDown() }
        let payload = Data(repeating: 0x41, count: 2048)
        let transferID = TransferID()
        let source = try environment.stage(payload, named: "note.txt")
        let measurement = FileMeasurement(data: payload)
        let clip = environment.localClip(
            [
                .file(ClipFileRepresentation(
                    mime: "text/plain",
                    name: "note.txt",
                    size: measurement.size,
                    sha256: measurement.sha256,
                    transferID: transferID
                )),
                .text("hello"),
            ],
            blobSources: [transferID: source]
        )
        let event = await environment.router.send(clip)
        let clips = await environment.transport.clips()
        let starts = await environment.transport.transferStarts()
        XCTAssertEqual(event?.kind, .clipSent)
        XCTAssertEqual(clips.count, 1)
        XCTAssertEqual(clips.first?.representations, [.text("hello")])
        XCTAssertTrue(starts.isEmpty)
    }
}
