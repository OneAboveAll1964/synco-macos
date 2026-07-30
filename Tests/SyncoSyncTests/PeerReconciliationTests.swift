import Foundation
import Network
import SyncoCore
import SyncoDiscovery
import XCTest
@testable import SyncoSync

final class PeerReconciliationTests: XCTestCase {
    private static let lower = DeviceID("aaaaaaaaaaaaaaaa")!
    private static let higher = DeviceID("zzzzzzzzzzzzzzzz")!

    func testLexicographicallySmallerDeviceIDDials() throws {
        let reconciliation = PeerReconciliation(localDeviceID: Self.lower)
        let peer = try Self.discovered(Self.higher)
        XCTAssertEqual(
            reconciliation.plan(discovered: peer, isTrusted: true, hasLiveSession: false),
            .dial(peer.endpoint)
        )
        XCTAssertEqual(reconciliation.decision(for: Self.higher), .dial)
        XCTAssertEqual(reconciliation.expectedOrigin(for: Self.higher), .dialed)
    }

    func testLexicographicallyLargerDeviceIDWaits() throws {
        let reconciliation = PeerReconciliation(localDeviceID: Self.higher)
        let peer = try Self.discovered(Self.lower)
        XCTAssertEqual(
            reconciliation.plan(discovered: peer, isTrusted: true, hasLiveSession: false),
            .awaitPeer
        )
        XCTAssertEqual(reconciliation.decision(for: Self.lower), .wait)
        XCTAssertEqual(reconciliation.expectedOrigin(for: Self.lower), .accepted)
    }

    func testUntrustedPeerIsNeverDialled() throws {
        let reconciliation = PeerReconciliation(localDeviceID: Self.lower)
        let peer = try Self.discovered(Self.higher)
        XCTAssertEqual(
            reconciliation.plan(discovered: peer, isTrusted: false, hasLiveSession: false),
            .unpaired
        )
    }

    func testUndiscoveredAndLinkedPeersStandBy() throws {
        let reconciliation = PeerReconciliation(localDeviceID: Self.lower)
        let peer = try Self.discovered(Self.higher)
        XCTAssertEqual(
            reconciliation.plan(discovered: nil, isTrusted: true, hasLiveSession: false),
            .standby
        )
        XCTAssertEqual(
            reconciliation.plan(discovered: peer, isTrusted: true, hasLiveSession: true),
            .standby
        )
    }

    func testArbitrationClosesTheSessionWithTheWrongInitiatorRole() {
        XCTAssertEqual(
            SessionArbitration.resolution(expected: .dialed, existing: nil, incoming: .accepted),
            .adoptIncoming
        )
        XCTAssertEqual(
            SessionArbitration.resolution(expected: .dialed, existing: .dialed, incoming: .accepted),
            .rejectIncoming
        )
        XCTAssertEqual(
            SessionArbitration.resolution(expected: .dialed, existing: .accepted, incoming: .dialed),
            .adoptIncoming
        )
        XCTAssertEqual(
            SessionArbitration.resolution(expected: .accepted, existing: .accepted, incoming: .dialed),
            .rejectIncoming
        )
    }

    private static func discovered(_ deviceID: DeviceID) throws -> DiscoveredPeer {
        DiscoveredPeer(
            advertisement: ServiceAdvertisement(
                deviceID: deviceID,
                displayName: "Peer",
                platform: .android,
                fingerprint: try Fingerprint(validatingCompact: "a1b2c3d4e5f60718")
            ),
            endpoint: .hostPort(host: "192.168.1.42", port: 51_234)
        )
    }
}
