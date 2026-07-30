import Foundation
@testable import SyncoCore

enum ControlMessageFixtures {
    static let localDeviceID = try! DeviceID(validating: "abcdefghij234567")
    static let peerDeviceID = try! DeviceID(validating: "zyxwvutsrq765432")
    static let fingerprint = try! Fingerprint(parsing: "A1B2-C3D4-E5F6-0718")
    static let clipID = ClipID(uuid: UUID(uuidString: "3F2A1B0C-4D5E-6F70-8192-A3B4C5D6E7F8")!)
    static let transferID = TransferID(uuid: UUID(uuidString: "11112222-3333-4444-5555-666677778888")!)
    static let imageDigest = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
    static let fileDigest = "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"

    static let representations: [ClipRepresentation] = [
        .text("hello"),
        .html("<b>hello</b>"),
        .rtf(Data([0x7B, 0x5C, 0x72, 0x74, 0x66, 0x31, 0x7D])),
        .url(ClipURLRepresentation(url: "https://example.com/a?b=c", title: "Example")),
        .image(ClipImageRepresentation(
            mime: "image/png",
            name: "shot.png",
            size: 91_234,
            sha256: imageDigest,
            transferID: transferID
        )),
        .file(ClipFileRepresentation(
            mime: "text/plain",
            name: "notes.txt",
            size: 12,
            sha256: fileDigest,
            transferID: transferID,
            rel: "docs/notes.txt"
        )),
    ]

    static let hello = HelloMessage(
        deviceID: localDeviceID,
        displayName: "Shko's Mac",
        platform: .macOS,
        ephemeralPublicKey: Data(repeating: 0x2B, count: 32)
    )
    static let auth = AuthMessage(tag: Data(repeating: 0x7C, count: 32))
    static let pairRequest = PairRequestMessage(
        deviceID: localDeviceID,
        displayName: "Shko's Mac",
        platform: .macOS,
        staticPublicKey: Data(repeating: 0x1A, count: 32),
        fingerprint: fingerprint
    )
    static let pairResponse = PairResponseMessage(
        accepted: true,
        deviceID: localDeviceID,
        staticPublicKey: Data(repeating: 0x1A, count: 32)
    )
    static let caps = CapsMessage(accepts: .all, sends: ClipTypeFlags(text: true, image: true, file: false))
    static let ping = PingMessage(seq: 12)
    static let pong = PongMessage(replyingTo: ping)
    static let clip = ClipMessage(
        id: clipID,
        timestampMilliseconds: 1_730_300_000_000,
        origin: peerDeviceID,
        hash: ClipCanonicalHash.hexDigest(for: representations),
        representations: representations
    )
    static let transferStart = TransferStartMessage(
        transferID: transferID,
        clipID: clipID,
        name: "shot.png",
        mime: "image/png",
        size: 91_234,
        sha256: imageDigest
    )
    static let transferEnd = TransferEndMessage(transferID: transferID, ok: true)
    static let transferAbort = TransferAbortMessage(transferID: transferID, reason: .tooLarge)
    static let appliedAck = AckMessage(id: clipID, applied: true)
    static let rejectedAck = AckMessage(id: clipID, applied: false, reason: .typeDisabled)
    static let bye = ByeMessage(reason: .shutdown)

    static let all: [ControlMessage] = [
        .hello(hello),
        .auth(auth),
        .pairRequest(pairRequest),
        .pairResponse(pairResponse),
        .caps(caps),
        .ping(ping),
        .pong(pong),
        .clip(clip),
        .transferStart(transferStart),
        .transferEnd(transferEnd),
        .transferAbort(transferAbort),
        .ack(appliedAck),
        .ack(rejectedAck),
        .bye(bye),
    ]
}
