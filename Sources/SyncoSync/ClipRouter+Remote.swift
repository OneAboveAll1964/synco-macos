import Foundation
import SyncoCore
import SyncoRemote

extension ClipRouter: RemoteHostDelegate {
    func startRemote(_ request: RemoteStartMessage) async {
        await wireRemoteIfNeeded()
        await remote.start(request)
    }

    private func wireRemoteIfNeeded() async {
        guard !remoteWired else { return }
        remoteWired = true
        await remote.setDelegate(self)
    }

    public func remoteHost(_ host: RemoteHost, didProduce frame: MediaFrame) async {
        try? await transport.send(frame)
    }

    public func remoteHost(_ host: RemoteHost, didAcceptWith accept: RemoteAcceptMessage) async {
        try? await transport.send(.remoteAccept(accept))
    }

    public func remoteHost(_ host: RemoteHost, didRejectWith reject: RemoteRejectMessage) async {
        try? await transport.send(.remoteReject(reject))
    }

    public func remoteHostDidStop(_ host: RemoteHost) async {
        try? await transport.send(.remoteStop(RemoteStopMessage()))
    }
}
