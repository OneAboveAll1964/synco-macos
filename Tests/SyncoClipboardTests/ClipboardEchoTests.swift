import AppKit
import SyncoCore
import XCTest
@testable import SyncoClipboard

final class ClipboardEchoTests: XCTestCase {

    @MainActor
    func testAnAppliedClipIsNotRebroadcastAsALocalCopy() async {
        let service = ClipboardService(deviceID: DeviceID("aaaabbbbccccdddd")!)
        let message = ClipMessage(
            id: ClipID(),
            timestampMilliseconds: 0,
            origin: DeviceID("eeeeffffgggghhhh")!,
            hash: "sender-side-hash-that-will-not-match",
            representations: [.text("echo-probe-payload")]
        )

        _ = await service.apply(message, receivedFiles: [:])

        // The monitor polls on a timer and can observe the intermediate change
        // count that clearContents() produces, slipping past the change-count
        // guard. Suppressing the exact hash we can read back is what stops the
        // applied clip from being rebroadcast as a local copy.
        let capture = await PasteboardCapture.systemPasteboard()
        let readback = PasteboardReader().read(capture)
        let suppressed = await service.suppression.contains(readback.canonicalHash)

        XCTAssertFalse(readback.isEmpty)
        XCTAssertTrue(suppressed, "the hash we can read back after applying must be suppressed")

        let clip = await service.currentClipForEchoCheck()
        XCTAssertNil(clip, "re-reading the pasteboard we just applied must not yield a local clip")
    }
}
