import Foundation
import SyncoCore
import SyncoCrypto
import SyncoSettings
import SyncoTransport
import XCTest
@testable import SyncoTransport
@testable import SyncoSync

final class QRTokenApprovalTests: XCTestCase {

    private func temporarySettings() -> SettingsStore {
        SettingsStore(storage: SettingsFileStorage(location: SettingsLocation(
            fileURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("synco-settings-\(UUID().uuidString).json")
        )))
    }

    private func proposal(token: String?) throws -> PairingProposal {
        let identity = try DeviceIdentity.generate()
        return try PairingProposal(request: PairRequestMessage(
            deviceID: identity.deviceID,
            displayName: "SM-S936B",
            platform: .android,
            staticPublicKey: identity.publicKey,
            fingerprint: identity.fingerprint,
            token: token
        ))
    }

    @MainActor
    func testAMatchingTokenApprovesSilentlyAndOnlyOnce() async throws {
        let coordinator = PairingCoordinator(
            state: SyncState(),
            settings: temporarySettings()
        )
        await coordinator.armQRToken("golden")

        let first = await coordinator.pairingDecision(for: try proposal(token: "golden"))
        XCTAssertEqual(first, .approve)

        let task = Task {
            await coordinator.pairingDecision(for: try self.proposal(token: "golden"))
        }
        try await Task.sleep(for: .milliseconds(150))
        task.cancel()
        let second = try await task.value
        XCTAssertEqual(second, .reject)
    }

    @MainActor
    func testTheTokenOutranksAnEarlierRejection() async throws {
        let coordinator = PairingCoordinator(
            state: SyncState(),
            settings: temporarySettings()
        )
        let proposal = try proposal(token: "golden")
        await coordinator.reject(proposal.deviceID)
        await coordinator.armQRToken("golden")

        let decision = await coordinator.pairingDecision(for: proposal)

        XCTAssertEqual(decision, .approve)
    }

    @MainActor
    func testAnExpiredTokenNoLongerApproves() async throws {
        let coordinator = PairingCoordinator(
            state: SyncState(),
            settings: temporarySettings(),
            qrTokenLifetime: .milliseconds(50)
        )
        await coordinator.armQRToken("golden")
        try await Task.sleep(for: .milliseconds(120))

        let task = Task {
            await coordinator.pairingDecision(for: try self.proposal(token: "golden"))
        }
        try await Task.sleep(for: .milliseconds(150))
        task.cancel()
        let decision = try await task.value

        XCTAssertEqual(decision, .reject)
    }

    @MainActor
    func testAWrongTokenFallsBackToAskingTheUser() async throws {
        let coordinator = PairingCoordinator(
            state: SyncState(),
            settings: temporarySettings()
        )
        await coordinator.armQRToken("golden")

        let task = Task {
            await coordinator.pairingDecision(for: try self.proposal(token: "forged"))
        }
        try await Task.sleep(for: .milliseconds(150))
        task.cancel()
        let decision = try await task.value
        XCTAssertEqual(decision, .reject)
    }
}
