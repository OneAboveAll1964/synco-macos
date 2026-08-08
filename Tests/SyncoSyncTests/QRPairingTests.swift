import Foundation
import SyncoCrypto
import XCTest
@testable import SyncoSync

final class QRPairingTests: XCTestCase {

    func testThePayloadCarriesEverythingThePhoneNeeds() throws {
        let identity = try DeviceIdentity.generate()

        let code = try XCTUnwrap(QRPairing.code(
            identity: identity,
            displayName: "Shko's MacBook Pro",
            hosts: ["192.168.1.20", "10.0.0.4"],
            port: 49_152
        ))
        let components = try XCTUnwrap(URLComponents(string: code.payload))
        let items = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        XCTAssertEqual(components.scheme, "synco")
        XCTAssertEqual(components.host, "pair")
        XCTAssertEqual(items["did"], identity.deviceID.rawValue)
        XCTAssertEqual(items["fp"], identity.fingerprint.grouped)
        XCTAssertEqual(items["port"], "49152")
        XCTAssertEqual(items["hosts"], "192.168.1.20,10.0.0.4")
        XCTAssertEqual(items["tok"], code.token)
        XCTAssertFalse(code.token.isEmpty)
    }

    func testNoCodeWithoutAReachableEndpoint() throws {
        let identity = try DeviceIdentity.generate()

        XCTAssertNil(QRPairing.code(identity: identity, displayName: "Mac", hosts: [], port: 1))
        XCTAssertNil(QRPairing.code(identity: identity, displayName: "Mac", hosts: ["10.0.0.4"], port: 0))
    }

    func testEveryTokenIsUnique() {
        XCTAssertNotEqual(QRPairing.token(), QRPairing.token())
    }
}
