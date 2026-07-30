import Foundation

public enum Base32 {
    public static let alphabet = "abcdefghijklmnopqrstuvwxyz234567"

    private static let encodeTable = Array(alphabet.utf8)

    public static func encode(_ data: Data) -> String {
        var output: [UInt8] = []
        output.reserveCapacity((data.count * 8 + 4) / 5)
        var accumulator: UInt32 = 0
        var pendingBits = 0
        for byte in data {
            accumulator = (accumulator << 8) | UInt32(byte)
            pendingBits += 8
            while pendingBits >= 5 {
                pendingBits -= 5
                output.append(encodeTable[Int((accumulator >> UInt32(pendingBits)) & 0x1F)])
            }
        }
        if pendingBits > 0 {
            output.append(encodeTable[Int((accumulator << UInt32(5 - pendingBits)) & 0x1F)])
        }
        return String(decoding: output, as: UTF8.self)
    }

    public static func decode(_ text: String) throws -> Data {
        var output = Data()
        output.reserveCapacity(text.utf8.count * 5 / 8)
        var accumulator: UInt32 = 0
        var pendingBits = 0
        for character in text.utf8 {
            guard let value = symbolValue(character) else {
                throw SyncoError.invalidBase32(text)
            }
            accumulator = (accumulator << 5) | UInt32(value)
            pendingBits += 5
            if pendingBits >= 8 {
                pendingBits -= 8
                output.append(UInt8((accumulator >> UInt32(pendingBits)) & 0xFF))
            }
        }
        let residueMask = (UInt32(1) << UInt32(pendingBits)) - 1
        guard pendingBits < 5, accumulator & residueMask == 0 else {
            throw SyncoError.invalidBase32(text)
        }
        return output
    }

    public static func isLowercaseSymbol(_ character: UInt8) -> Bool {
        switch character {
        case UInt8(ascii: "a")...UInt8(ascii: "z"), UInt8(ascii: "2")...UInt8(ascii: "7"):
            return true
        default:
            return false
        }
    }

    private static func symbolValue(_ character: UInt8) -> UInt8? {
        switch character {
        case UInt8(ascii: "a")...UInt8(ascii: "z"):
            return character - UInt8(ascii: "a")
        case UInt8(ascii: "A")...UInt8(ascii: "Z"):
            return character - UInt8(ascii: "A")
        case UInt8(ascii: "2")...UInt8(ascii: "7"):
            return character - UInt8(ascii: "2") + 26
        default:
            return nil
        }
    }
}
