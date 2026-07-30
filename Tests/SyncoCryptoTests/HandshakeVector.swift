import Foundation
import SyncoCore
@testable import SyncoCrypto

enum HandshakeVector {
    static let staticPrivateKeyA = "c91db89009baf4c6f27ab832cd9fbd2c421a07a7af848792947f2c0ae68ca75d"
    static let staticPrivateKeyB = "cae7099dd98cfbd0a92efbe06348580d4366b8f672768919325c0c4b97904678"
    static let ephemeralPrivateKeyA = "497e423ea25e408cf687f1f23d705744350bc996f552d04d3ae3646b67a24205"
    static let ephemeralPrivateKeyB = "7412338f65fc71d038bb226e048f927ab751adf2de16082ddc7c50d0d70cae02"

    static let staticPublicKeyA = "1cdf59b969090b0a53df667187dbe8611e795ac495ed68e82bc8e95bae7bd50b"
    static let staticPublicKeyB = "17cd0e9808530b546ae99a08f40f633d94f04037edccb4c989c73ca96315f145"
    static let ephemeralPublicKeyA = "cac809acae4ed4c8e6ff5a6a03a6611c6840662a1ec3a063f000fdec8a540c30"
    static let ephemeralPublicKeyB = "431ec0d04c9298cd8bbca32332e7a68835fd93547dcd9ccd5ee2c7ca97c6b41a"

    static let deviceIDA = "uiodmijekrdpyxzt"
    static let deviceIDB = "e2p5ayh3va6xq2mo"

    static let salt = "8c6cc91b0e5c0c2bef37fffccb8e4bb2438981edf4093cd461ef66606adf8d1b"
    static let initiatorToResponderKey = "8ef0ec9f6cc59b5d128365bdb0948626ec7083116241b257e148701f15248007"
    static let responderToInitiatorKey = "9a6f20984f29cd528b27bd03908056e5245d325f0f7534891e5e0dc9bb9f1c99"
    static let initiatorTag = "3f2a6eedf2793a0a7f4bd4c8c64243bb820b1ef52f90c1b43fb0c067640d1f6d"
    static let responderTag = "0cd275da23ab630d5c66a1b34d6765b8ea396378f711069bf37830286255cde1"

    static func identity(_ hexPrivateKey: String) throws -> DeviceIdentity {
        try DeviceIdentity(privateKeyRepresentation: try HexEncoding.decode(hexPrivateKey))
    }

    static func ephemeral(_ hexPrivateKey: String) throws -> EphemeralKeyPair {
        try EphemeralKeyPair.restored(privateKeyRepresentation: try HexEncoding.decode(hexPrivateKey))
    }
}
