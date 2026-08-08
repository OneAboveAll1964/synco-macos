import CoreMedia
import Foundation
import ScreenCaptureKit

public struct RemoteScreenSize: Sendable, Hashable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public final class ScreenCapture: NSObject, SCStreamOutput, @unchecked Sendable {
    private var stream: SCStream?
    private let onFrame: @Sendable (CVPixelBuffer, UInt64) -> Void
    private let queue = DispatchQueue(label: "com.shkomaghdid.synco.macos.remote.capture")

    public private(set) var size = RemoteScreenSize(width: 0, height: 0)

    public init(onFrame: @escaping @Sendable (CVPixelBuffer, UInt64) -> Void) {
        self.onFrame = onFrame
    }

    public static func fittedSize(display: SCDisplay, maxWidth: Int, maxHeight: Int) -> RemoteScreenSize {
        let scale = min(
            Double(maxWidth) / Double(display.width),
            Double(maxHeight) / Double(display.height),
            1.0
        )
        let width = Int((Double(display.width) * scale).rounded(.down)) & ~1
        let height = Int((Double(display.height) * scale).rounded(.down)) & ~1
        return RemoteScreenSize(width: max(2, width), height: max(2, height))
    }

    public func start(maxWidth: Int, maxHeight: Int, fps: Int) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else {
            throw RemoteCaptureError.noDisplay
        }
        let fitted = Self.fittedSize(display: display, maxWidth: maxWidth, maxHeight: maxHeight)
        size = fitted

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.width = fitted.width
        configuration.height = fitted.height
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(fps))
        configuration.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        configuration.queueDepth = 5
        configuration.showsCursor = true

        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
        try await stream.startCapture()
        self.stream = stream
    }

    public func stop() async {
        guard let stream else { return }
        try? await stream.stopCapture()
        self.stream = nil
    }

    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return
        }
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
            as? [[SCStreamFrameInfo: Any]],
            let status = attachments.first?[.status] as? Int,
            status == SCFrameStatus.complete.rawValue
        else {
            return
        }
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        onFrame(pixelBuffer, UInt64(max(0, pts.seconds * 1_000_000)))
    }
}

public enum RemoteCaptureError: Error, Sendable {
    case noDisplay
}
