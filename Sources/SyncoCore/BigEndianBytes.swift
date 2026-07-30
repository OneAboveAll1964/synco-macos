import Foundation

public enum BigEndianBytes {
    public static func encode(_ value: UInt32) -> Data {
        withUnsafeBytes(of: value.bigEndian) { Data($0) }
    }

    public static func encode(_ value: UInt64) -> Data {
        withUnsafeBytes(of: value.bigEndian) { Data($0) }
    }

    public static func uint32(_ bytes: Data) -> UInt32? {
        guard bytes.count == 4 else { return nil }
        var value: UInt32 = 0
        for byte in bytes { value = value << 8 | UInt32(byte) }
        return value
    }

    public static func uint64(_ bytes: Data) -> UInt64? {
        guard bytes.count == 8 else { return nil }
        var value: UInt64 = 0
        for byte in bytes { value = value << 8 | UInt64(byte) }
        return value
    }
}
