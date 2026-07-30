import Foundation
import SyncoCore
import SyncoCrypto
import XCTest
@testable import SyncoTransport

final class PeerSessionPairingTests: XCTestCase {
    func testUnknownPeerNeverReachesKeyDerivation() async throws {
        let (local, remote) = try PeerSessionFixture.distinctIdentities()
        let pair = try await Loopback.pair()
        defer { pair.close() }
        let localSession = PeerSession(
            connection: pair.client,
            configuration: PeerSessionFixture.configuration(
                identity: local,
                trusting: [],
                approving: .approve
            )
        )
        let remoteSession = PeerSession(
            connection: pair.server,
            configuration: PeerSessionFixture.configuration(
                identity: remote,
                trusting: [],
                approving: .approve
            )
        )
        let localEvents = SessionEventRecorder()
        let remoteEvents = SessionEventRecorder()
        await localEvents.consume(await localSession.start())
        await remoteEvents.consume(await remoteSession.start())

        let settlement = try await localEvents.wait { event -> PairingSettlement? in
            guard case .pairingSettled(let value) = event else { return nil }
            return value
        }
        XCTAssertTrue(settlement.isAgreed)
        XCTAssertEqual(settlement.proposal.deviceID, remote.deviceID)
        XCTAssertEqual(settlement.proposal.staticPublicKey, remote.publicKey)
        XCTAssertEqual(settlement.proposal.fingerprint, remote.fingerprint)

        let reason = try await localEvents.wait { $0.terminalReason }
        XCTAssertEqual(reason, .unpaired)
        let recorded = await localEvents.snapshot()
        XCTAssertFalse(recorded.contains { event in
            guard case .established = event else { return false }
            return true
        })
        _ = try await remoteEvents.wait { $0.terminalReason }
        await localEvents.stop()
        await remoteEvents.stop()
    }
}
