import Foundation
import SyncoCore
import SyncoTransfer
import XCTest
@testable import SyncoSync

final class ClipRouterInboundTests: XCTestCase {
    func testIgnoresClipThatOriginatedOnThisDevice() async {
        let environment = ClipRouterEnvironment()
        defer { environment.tearDown() }
        let clip = environment.incomingClip(
            [.text("loop")],
            origin: ClipRouterEnvironment.localDeviceID
        )
        let event = await environment.router.handle(.clip(clip))
        let applied = await environment.clipboard.appliedClips()
        let messages = await environment.transport.recordedMessages()
        XCTAssertNil(event)
        XCTAssertTrue(applied.isEmpty)
        XCTAssertTrue(messages.isEmpty)
    }

    func testRejectsClipWhenReceivingIsDisabled() async {
        let environment = ClipRouterEnvironment(
            policy: ClipRouterEnvironment.policy(send: .all, receive: .none)
        )
        defer { environment.tearDown() }
        let event = await environment.router.handle(.clip(environment.incomingClip([.text("hi")])))
        let acks = await environment.transport.acks()
        let applied = await environment.clipboard.appliedClips()
        XCTAssertEqual(event?.kind, .clipRejected(.receiveDisabled))
        XCTAssertEqual(acks.count, 1)
        XCTAssertEqual(acks.first?.applied, false)
        XCTAssertEqual(acks.first?.reason, .receiveDisabled)
        XCTAssertTrue(applied.isEmpty)
    }

    func testRejectsClipWhoseOnlyRepresentationTypeIsDisabled() async {
        let environment = ClipRouterEnvironment(
            policy: ClipRouterEnvironment.policy(
                send: .all,
                receive: ClipTypeFlags(text: true, image: false, file: false)
            )
        )
        defer { environment.tearDown() }
        let clip = environment.incomingClip([
            .image(ClipImageRepresentation(
                mime: "image/png",
                name: "shot.png",
                size: 12,
                sha256: String(repeating: "a", count: 64),
                transferID: TransferID()
            )),
        ])
        let event = await environment.router.handle(.clip(clip))
        let acks = await environment.transport.acks()
        XCTAssertEqual(event?.kind, .clipRejected(.typeDisabled))
        XCTAssertEqual(acks.first?.reason, .typeDisabled)
    }

    func testAppliesInlineClipAndAcknowledges() async {
        let environment = ClipRouterEnvironment()
        defer { environment.tearDown() }
        let clip = environment.incomingClip([.html("<b>hi</b>"), .text("hi")])
        let event = await environment.router.handle(.clip(clip))
        let applied = await environment.clipboard.appliedClips()
        let acks = await environment.transport.acks()
        XCTAssertEqual(event?.kind, .clipReceived)
        XCTAssertEqual(applied.count, 1)
        XCTAssertEqual(applied.first?.hash, clip.hash)
        XCTAssertEqual(applied.first?.representations, clip.representations)
        XCTAssertEqual(acks.first?.applied, true)
        XCTAssertNil(acks.first?.reason)
    }

    func testAcknowledgesRejectionWhenTheClipboardRefusesTheWrite() async {
        let environment = ClipRouterEnvironment()
        defer { environment.tearDown() }
        await environment.clipboard.setOutcome(false)
        let event = await environment.router.handle(.clip(environment.incomingClip([.text("hi")])))
        let acks = await environment.transport.acks()
        XCTAssertEqual(event?.kind, .clipRejected(.userCancelled))
        XCTAssertEqual(acks.first?.applied, false)
        XCTAssertEqual(acks.first?.reason, .userCancelled)
    }

    func testReportsPeerRejectionCarriedByAck() async {
        let environment = ClipRouterEnvironment()
        defer { environment.tearDown() }
        let identifier = ClipID()
        let event = await environment.router.handle(
            .ack(AckMessage(id: identifier, applied: false, reason: .tooLarge))
        )
        XCTAssertEqual(event?.kind, .clipRejected(.tooLarge))
        XCTAssertEqual(event?.clipID, identifier)
    }
}
