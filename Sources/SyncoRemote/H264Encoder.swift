import CoreMedia
import Foundation
import VideoToolbox

public struct EncodedPicture: Sendable {
    public let data: Data
    public let ptsMicros: UInt64
    public let isKeyframe: Bool
    public let isConfig: Bool
}

public final class H264Encoder: @unchecked Sendable {
    private var session: VTCompressionSession?
    private let width: Int32
    private let height: Int32
    private let fps: Int32
    private let onPicture: @Sendable (EncodedPicture) -> Void

    public init(
        width: Int,
        height: Int,
        fps: Int,
        onPicture: @escaping @Sendable (EncodedPicture) -> Void
    ) {
        self.width = Int32(width)
        self.height = Int32(height)
        self.fps = Int32(fps)
        self.onPicture = onPicture
    }

    public func start() -> Bool {
        var created: VTCompressionSession?
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: nil,
            refcon: nil,
            compressionSessionOut: &created
        )
        guard status == noErr, let created else { return false }
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: (fps * 2) as CFNumber)
        VTSessionSetProperty(created, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: fps as CFNumber)
        VTCompressionSessionPrepareToEncodeFrames(created)
        session = created
        return true
    }

    public func encode(_ pixelBuffer: CVPixelBuffer, ptsMicros: UInt64) {
        guard let session else { return }
        let presentation = CMTime(value: CMTimeValue(ptsMicros), timescale: 1_000_000)
        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: presentation,
            duration: .invalid,
            frameProperties: nil,
            infoFlagsOut: nil
        ) { [weak self] status, _, sampleBuffer in
            guard status == noErr, let sampleBuffer else { return }
            self?.emit(sampleBuffer)
        }
    }

    public func stop() {
        guard let session else { return }
        VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
        VTCompressionSessionInvalidate(session)
        self.session = nil
    }

    private func emit(_ sampleBuffer: CMSampleBuffer) {
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let micros = UInt64(max(0, pts.seconds * 1_000_000))
        let keyframe = AnnexBConverter.isKeyframe(sampleBuffer)
        if keyframe, let format = CMSampleBufferGetFormatDescription(sampleBuffer),
           let config = AnnexBConverter.parameterSets(from: format) {
            onPicture(EncodedPicture(data: config, ptsMicros: micros, isKeyframe: false, isConfig: true))
        }
        if let annexB = AnnexBConverter.annexB(from: sampleBuffer) {
            onPicture(EncodedPicture(data: annexB, ptsMicros: micros, isKeyframe: keyframe, isConfig: false))
        }
    }
}
