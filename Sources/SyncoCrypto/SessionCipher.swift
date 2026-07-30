import CryptoKit
import Foundation
import SyncoCore

public struct SessionCipher: Sendable {
    private let key: SymmetricKey
    public private(set) var counter: UInt64 = 0

    public init(key: Data) {
        self.key = SymmetricKey(data: key)
    }

    public mutating func seal(_ plaintext: Data) throws -> Data {
        try requireCounterHeadroom()
        let nonce = try nonce(for: counter)
        guard let box = try? ChaChaPoly.seal(plaintext, using: key, nonce: nonce) else {
            throw SyncoError.malformedRecord
        }
        counter += 1
        var output = Data(capacity: box.ciphertext.count + box.tag.count)
        output.append(box.ciphertext)
        output.append(box.tag)
        return output
    }

    public mutating func open(_ record: Data) throws -> Data {
        try requireCounterHeadroom()
        let tagBytes = SyncoConstants.Record.authenticationTagBytes
        guard record.count > tagBytes else { throw SyncoError.malformedRecord }
        let rebased = Data(record)
        let ciphertext = Data(rebased.prefix(rebased.count - tagBytes))
        let tag = Data(rebased.suffix(tagBytes))
        let nonce = try nonce(for: counter)
        guard let box = try? ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag),
              let plaintext = try? ChaChaPoly.open(box, using: key)
        else {
            throw SyncoError.replay
        }
        counter += 1
        return plaintext
    }

    private func requireCounterHeadroom() throws {
        guard counter < UInt64.max - 1 else { throw SyncoError.nonceExhausted }
    }

    private func nonce(for value: UInt64) throws -> ChaChaPoly.Nonce {
        var material = Data(repeating: 0, count: SyncoConstants.Record.noncePrefixBytes)
        material.append(BigEndianBytes.encode(value))
        guard let nonce = try? ChaChaPoly.Nonce(data: material) else {
            throw SyncoError.malformedRecord
        }
        return nonce
    }
}
