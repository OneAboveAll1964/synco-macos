import SyncoCore
import XCTest
@testable import SyncoRemote

private actor PictureCollector {
    private(set) var pictures: [EncodedPicture] = []

    func add(_ picture: EncodedPicture) {
        pictures.append(picture)
    }
}

final class LiveCaptureTests: XCTestCase {

    func testCapturesEncodesAndFragmentsTheScreen() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SYNCO_LIVE_CAPTURE"] == "1")
        try XCTSkipUnless(RemoteScreenPermission.current() == .granted)

        let plan = try await ScreenCapture.plan(maxWidth: 1280, maxHeight: 2400)
        let collector = PictureCollector()
        let encoder = H264Encoder(width: plan.size.width, height: plan.size.height, fps: 60) { picture in
            Task { await collector.add(picture) }
        }
        XCTAssertTrue(encoder.start())

        let capture = ScreenCapture { [encoder] pixelBuffer, pts in
            encoder.encode(pixelBuffer, ptsMicros: pts)
        }
        try await capture.start(maxWidth: 1280, maxHeight: 2400, fps: 60)
        try await Task.sleep(for: .seconds(3))
        await capture.stop()
        encoder.stop()

        let pictures = await collector.pictures
        XCTAssertTrue(pictures.contains { $0.isConfig }, "no parameter sets were emitted")
        XCTAssertTrue(pictures.contains { $0.isKeyframe }, "no keyframe was emitted")
        XCTAssertGreaterThan(pictures.count, 10, "too few pictures for three seconds")

        let fragmenter = MediaFrameFragmenter()
        for (index, picture) in pictures.enumerated() {
            let frames = fragmenter.fragments(for: picture, seq: UInt32(index))
            XCTAssertFalse(frames.isEmpty)
            XCTAssertEqual(frames.map(\.data).reduce(Data(), +), picture.data)
            for frame in frames {
                XCTAssertLessThanOrEqual(frame.encoded().count, SyncoConstants.Framing.maxPayloadBytes)
            }
        }

        let bytes = pictures.reduce(0) { $0 + $1.data.count }
        print("live capture: \(plan.size.width)x\(plan.size.height), \(pictures.count) pictures, \(bytes / 1024) KiB")
    }

    @MainActor
    func testMovesTheRealPointer() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SYNCO_LIVE_CAPTURE"] == "1")
        try XCTSkipUnless(RemoteInputPermission.current() == .granted)

        let bounds = try await ScreenCapture.plan(maxWidth: 1280, maxHeight: 2400).bounds
        let injector = RemoteInputInjector(bounds: bounds)
        let origin = CGEvent(source: nil)?.location ?? .zero

        injector.inject(RemoteInputEvent(kind: "pa", x: 0.25, y: 0.75))
        try await Task.sleep(for: .milliseconds(120))
        let moved = CGEvent(source: nil)?.location ?? .zero
        XCTAssertEqual(moved.x, bounds.minX + bounds.width * 0.25, accuracy: 2)
        XCTAssertEqual(moved.y, bounds.minY + bounds.height * 0.75, accuracy: 2)

        injector.inject(RemoteInputEvent(
            kind: "pm",
            dx: Double(origin.x - moved.x),
            dy: Double(origin.y - moved.y)
        ))
    }
}
