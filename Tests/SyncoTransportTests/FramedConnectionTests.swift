import Foundation
import SyncoCore
import XCTest
@testable import SyncoTransport

final class FramedConnectionTests: XCTestCase {
    private let readTimeout = Duration.seconds(3)

    func testFramesRoundTripInBothDirections() async throws {
        let pair = try await Loopback.pair()
        defer { pair.close() }
        let outbound = [
            Data([0x01]),
            Data("framing".utf8),
            Data(repeating: 0xAB, count: 70_000),
        ]
        for payload in outbound {
            try await pair.client.send(frame: payload)
        }
        for payload in outbound {
            let received = try await TimeLimit.run(readTimeout) {
                try await pair.server.receiveFrame()
            }
            XCTAssertEqual(received, payload)
        }
        let reply = Data(repeating: 0x5A, count: 300_000)
        try await pair.server.send(frame: reply)
        let echoed = try await TimeLimit.run(readTimeout) {
            try await pair.client.receiveFrame()
        }
        XCTAssertEqual(echoed, reply)
    }

    func testEmptyAndOversizedFramesAreRejectedBeforeTheWire() async throws {
        let pair = try await Loopback.pair()
        defer { pair.close() }
        let oversized = SyncoConstants.Framing.maxPayloadBytes + 1
        XCTAssertThrowsError(try pair.client.write(frame: Data(count: oversized))) { error in
            XCTAssertEqual(error as? SyncoError, .frameTooLarge(UInt32(oversized)))
        }
        XCTAssertThrowsError(try pair.client.write(frame: Data())) { error in
            XCTAssertEqual(error as? SyncoError, .invalidFrameLength(0))
        }
    }

    func testFrameLargerThanTheReceiverCapIsRejected() async throws {
        let pair = try await Loopback.pair(serverMaxPayloadBytes: 4_096)
        defer { pair.close() }
        try await pair.client.send(frame: Data(repeating: 0x7F, count: 5_000))
        do {
            _ = try await TimeLimit.run(readTimeout) { try await pair.server.receiveFrame() }
            XCTFail("expected the oversized frame to be rejected")
        } catch {
            XCTAssertEqual(error as? SyncoError, .frameTooLarge(5_000))
        }
    }

    func testReceivingAfterThePeerClosesFails() async throws {
        let pair = try await Loopback.pair()
        defer { pair.close() }
        pair.client.close()
        do {
            _ = try await TimeLimit.run(readTimeout) { try await pair.server.receiveFrame() }
            XCTFail("expected the closed connection to fail the read")
        } catch let error as TransportError {
            XCTAssertTrue(error == .connectionClosed || isFailure(error))
        }
    }

    private func isFailure(_ error: TransportError) -> Bool {
        guard case .connectionFailed = error else { return false }
        return true
    }
}
