import SyncoCore
import XCTest
@testable import SyncoCrypto

final class SessionCipherTests: XCTestCase {
    private let key = Data(repeating: 0x42, count: SyncoConstants.Handshake.sessionKeyBytes)

    func testSealAndOpenRoundTrip() throws {
        var sender = SessionCipher(key: key)
        var receiver = SessionCipher(key: key)
        for index in 0..<8 {
            let plaintext = Data("record \(index)".utf8)
            let record = try sender.seal(plaintext)
            XCTAssertEqual(record.count, plaintext.count + SyncoConstants.Record.authenticationTagBytes)
            XCTAssertEqual(try receiver.open(record), plaintext)
        }
        XCTAssertEqual(sender.counter, 8)
        XCTAssertEqual(receiver.counter, 8)
    }

    func testFramePayloadRoundTrip() throws {
        var sender = SessionCipher(key: key)
        var receiver = SessionCipher(key: key)
        let payload = FramePayload.control(Data("{\"t\":\"ping\",\"seq\":1}".utf8))
        let record = try sender.seal(payload.encoded())
        XCTAssertEqual(try FramePayload.decode(try receiver.open(record)), payload)
    }

    func testNonceAdvancesSoIdenticalPlaintextsProduceDifferentRecords() throws {
        var sender = SessionCipher(key: key)
        let plaintext = Data("same".utf8)
        let first = try sender.seal(plaintext)
        let second = try sender.seal(plaintext)
        XCTAssertNotEqual(first, second)
    }

    func testReplayedRecordIsRejected() throws {
        var sender = SessionCipher(key: key)
        var receiver = SessionCipher(key: key)
        let record = try sender.seal(Data("once".utf8))
        XCTAssertEqual(try receiver.open(record), Data("once".utf8))
        XCTAssertThrowsError(try receiver.open(record)) { error in
            XCTAssertEqual(error as? SyncoError, .replay)
        }
    }

    func testReorderedRecordsAreRejected() throws {
        var sender = SessionCipher(key: key)
        var receiver = SessionCipher(key: key)
        let first = try sender.seal(Data("first".utf8))
        let second = try sender.seal(Data("second".utf8))
        XCTAssertThrowsError(try receiver.open(second)) { error in
            XCTAssertEqual(error as? SyncoError, .replay)
        }
        XCTAssertEqual(receiver.counter, 0)
        XCTAssertEqual(try receiver.open(first), Data("first".utf8))
    }

    func testTamperedCiphertextIsRejected() throws {
        var sender = SessionCipher(key: key)
        var receiver = SessionCipher(key: key)
        var record = try sender.seal(Data("payload".utf8))
        record[0] ^= 0xFF
        XCTAssertThrowsError(try receiver.open(record)) { error in
            XCTAssertEqual(error as? SyncoError, .replay)
        }
    }

    func testTamperedAuthenticationTagIsRejected() throws {
        var sender = SessionCipher(key: key)
        var receiver = SessionCipher(key: key)
        var record = try sender.seal(Data("payload".utf8))
        let lastIndex = record.index(before: record.endIndex)
        record[lastIndex] ^= 0xFF
        XCTAssertThrowsError(try receiver.open(record)) { error in
            XCTAssertEqual(error as? SyncoError, .replay)
        }
    }

    func testWrongDirectionKeyIsRejected() throws {
        var sender = SessionCipher(key: key)
        var receiver = SessionCipher(key: Data(repeating: 0x43, count: SyncoConstants.Handshake.sessionKeyBytes))
        let record = try sender.seal(Data("payload".utf8))
        XCTAssertThrowsError(try receiver.open(record)) { error in
            XCTAssertEqual(error as? SyncoError, .replay)
        }
    }

    func testRecordShorterThanTheTagIsRejected() {
        var receiver = SessionCipher(key: key)
        XCTAssertThrowsError(try receiver.open(Data(repeating: 0, count: 16))) { error in
            XCTAssertEqual(error as? SyncoError, .malformedRecord)
        }
    }

    func testCountersStartAtZeroWhenTheSessionIsEstablished() throws {
        let session = try HandshakeSessionPair()
        XCTAssertEqual(session.initiatorResult.makeSendCipher().counter, 0)
        XCTAssertEqual(session.initiatorResult.makeReceiveCipher().counter, 0)
    }

    func testHandshakeKeysProduceInteroperableDirections() throws {
        let session = try HandshakeSessionPair()
        var initiatorSend = session.initiatorResult.makeSendCipher()
        var responderReceive = session.responderResult.makeReceiveCipher()
        var responderSend = session.responderResult.makeSendCipher()
        var initiatorReceive = session.initiatorResult.makeReceiveCipher()
        let toResponder = try initiatorSend.seal(Data("to responder".utf8))
        let toInitiator = try responderSend.seal(Data("to initiator".utf8))
        XCTAssertEqual(try responderReceive.open(toResponder), Data("to responder".utf8))
        XCTAssertEqual(try initiatorReceive.open(toInitiator), Data("to initiator".utf8))
    }
}
