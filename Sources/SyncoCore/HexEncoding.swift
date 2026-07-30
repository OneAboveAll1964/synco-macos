import Foundation

public enum HexEncoding {
    private static let lowercaseDigits = Array("0123456789abcdef".utf8)
    private static let uppercaseDigits = Array("0123456789ABCDEF".utf8)

    public static func encode(_ data: Data, uppercase: Bool = false) -> String {
        let digits = uppercase ? uppercaseDigits : lowercaseDigits
        var output: [UInt8] = []
        output.reserveCapacity(data.count * 2)
        for byte in data {
            output.append(digits[Int(byte >> 4)])
            output.append(digits[Int(byte & 0x0F)])
        }
        return String(decoding: output, as: UTF8.self)
    }

    public static func decode(_ text: String) throws -> Data {
        let characters = Array(text.utf8)
        guard characters.count % 2 == 0 else { throw SyncoError.invalidHexadecimal(text) }
        var output = Data()
        output.reserveCapacity(characters.count / 2)
        var index = 0
        while index < characters.count {
            guard let high = nibble(characters[index]), let low = nibble(characters[index + 1]) else {
                throw SyncoError.invalidHexadecimal(text)
            }
            output.append(high << 4 | low)
            index += 2
        }
        return output
    }

    public static func isHexadecimal(_ character: UInt8) -> Bool {
        nibble(character) != nil
    }

    private static func nibble(_ character: UInt8) -> UInt8? {
        switch character {
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
            return character - UInt8(ascii: "0")
        case UInt8(ascii: "a")...UInt8(ascii: "f"):
            return character - UInt8(ascii: "a") + 10
        case UInt8(ascii: "A")...UInt8(ascii: "F"):
            return character - UInt8(ascii: "A") + 10
        default:
            return nil
        }
    }
}
