import Foundation
import SyncoCore
import SyncoCrypto
import XCTest
@testable import SyncoTransport

final class PeerSessionHandshakeTests: XCTestCase {
    func testTrustedPeersHandshakeAndExchangeEncryptedEnvelopes() async throws {
        let (local, remote) = try PeerSessionFixture.distinctIdentities()
        let pair = try await Loopback.pair()
        defer { pair.close() }
        let localSession = PeerSession(
            connection: pair.client,
            configuration: PeerSessionFixture.configuration(identity: local, trusting: [remote])
        )
        let remoteSession = PeerSession(
            connection: pair.server,
            configuration: PeerSessionFixture.configuration(identity: remote, trusting: [local])
        )
        let localEvents = SessionEventRecorder()
        let remoteEvents = SessionEventRecorder()
        await localEvents.consume(await localSession.start())
        await remoteEvents.consume(await remoteSession.start())

        let localRole = try await localEvents.wait { event -> HandshakeRole? in
            guard case .established(let peer, let role) = event, peer.deviceID == remote.deviceID else {
                return nil
            }
            return role
        }
        let remoteRole = try await remoteEvents.wait { event -> HandshakeRole? in
            guard case .established(let peer, let role) = event, peer.deviceID == local.deviceID else {
                return nil
            }
            return role
        }
        XCTAssertNotEqual(localRole, remoteRole)
        XCTAssertEqual(
            localRole,
            HandshakeRole.role(localDeviceID: local.deviceID, peerDeviceID: remote.deviceID)
        )

        let clip = PeerSessionFixture.textClip(origin: local.deviceID, text: "sync me")
        try await localSession.send(.clip(clip))
        let receivedClip = try await remoteEvents.wait { event -> ClipMessage? in
            guard case .control(.clip(let message)) = event else { return nil }
            return message
        }
        XCTAssertEqual(receivedClip.id, clip.id)
        XCTAssertEqual(receivedClip.hash, clip.hash)
        XCTAssertEqual(receivedClip.representations, clip.representations)

        let caps = CapsMessage(accepts: .all, sends: ClipTypeFlags(text: true, image: true, file: false))
        try await remoteSession.send(.caps(caps))
        let receivedCaps = try await localEvents.wait { event -> CapsMessage? in
            guard case .control(.caps(let message)) = event else { return nil }
            return message
        }
        XCTAssertEqual(receivedCaps, caps)

        let chunk = BlobChunk(
            transferID: TransferID(),
            offset: 4_096,
            data: Data(repeating: 0x11, count: 2_048)
        )
        try await localSession.send(chunk)
        let receivedChunk = try await remoteEvents.wait { event -> BlobChunk? in
            guard case .blobChunk(let value) = event else { return nil }
            return value
        }
        XCTAssertEqual(receivedChunk, chunk)

        await localSession.close(reason: .shutdown)
        let remoteReason = try await remoteEvents.wait { $0.terminalReason }
        XCTAssertEqual(remoteReason, .shutdown)
        let localReason = try await localEvents.wait { $0.terminalReason }
        XCTAssertEqual(localReason, .shutdown)
        await localEvents.stop()
        await remoteEvents.stop()
    }
}
