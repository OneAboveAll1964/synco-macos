import CoreGraphics
import CoreMedia
import Foundation
import SyncoCore

public actor RemoteHost {
    public weak var delegate: RemoteHostDelegate?

    private var capture: ScreenCapture?
    private var encoder: H264Encoder?
    private var injector: RemoteInputInjector?
    private let fragmenter = MediaFrameFragmenter()
    private var seq: UInt32 = 0
    private var active = false

    public init() {}

    public func setDelegate(_ delegate: RemoteHostDelegate) {
        self.delegate = delegate
    }

    public func start(_ request: RemoteStartMessage) async {
        guard !active else {
            await delegate?.remoteHost(self, didRejectWith: RemoteRejectMessage(reason: .busy))
            return
        }
        guard RemoteScreenPermission.current() == .granted else {
            RemoteScreenPermission.request()
            await delegate?.remoteHost(self, didRejectWith: RemoteRejectMessage(reason: .screenPermission))
            return
        }
        let inputWanted = request.input
        let inputGranted = RemoteInputPermission.current() == .granted
        if inputWanted, !inputGranted {
            RemoteInputPermission.request()
        }
        do {
            try await beginCapture(request: request, input: inputWanted && inputGranted)
        } catch {
            await delegate?.remoteHost(self, didRejectWith: RemoteRejectMessage(reason: .screenPermission))
        }
    }

    private func beginCapture(request: RemoteStartMessage, input: Bool) async throws {
        let plan = try await ScreenCapture.plan(maxWidth: request.maxWidth, maxHeight: request.maxHeight)
        let size = plan.size

        let encoder = H264Encoder(width: size.width, height: size.height, fps: request.fps) { [weak self] picture in
            Task { await self?.onEncoded(picture) }
        }
        guard encoder.start() else { throw RemoteCaptureError.noDisplay }
        let capture = ScreenCapture { [encoder] pixelBuffer, pts in
            encoder.encode(pixelBuffer, ptsMicros: pts)
        }
        try await capture.start(maxWidth: request.maxWidth, maxHeight: request.maxHeight, fps: request.fps)
        self.capture = capture
        self.encoder = encoder
        if input {
            injector = await RemoteInputInjector(bounds: plan.bounds)
        }
        active = true
        seq = 0
        await delegate?.remoteHost(self, didAcceptWith: RemoteAcceptMessage(
            width: size.width, height: size.height, fps: request.fps, input: input
        ))
    }

    public func stop() async {
        guard active else { return }
        active = false
        await capture?.stop()
        encoder?.stop()
        capture = nil
        encoder = nil
        injector = nil
        await delegate?.remoteHostDidStop(self)
    }

    public func handleInput(_ message: RemoteInputMessage) async {
        guard let injector else { return }
        for event in message.events {
            await injector.inject(event)
        }
    }

    private func onEncoded(_ picture: EncodedPicture) async {
        guard active else { return }
        if !picture.isConfig { seq &+= 1 }
        for frame in fragmenter.fragments(for: picture, seq: seq) {
            await delegate?.remoteHost(self, didProduce: frame)
        }
    }
}
