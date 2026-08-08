import CoreMedia
import Foundation

enum AnnexBConverter {
    private static let startCode = Data([0x00, 0x00, 0x00, 0x01])

    static func parameterSets(from format: CMFormatDescription) -> Data? {
        var count = 0
        var naluHeaderLength: Int32 = 0
        let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            format, parameterSetIndex: 0, parameterSetPointerOut: nil,
            parameterSetSizeOut: nil, parameterSetCountOut: &count, nalUnitHeaderLengthOut: &naluHeaderLength
        )
        guard status == noErr, count > 0 else { return nil }
        var output = Data()
        for index in 0..<count {
            var pointer: UnsafePointer<UInt8>?
            var size = 0
            let result = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                format, parameterSetIndex: index, parameterSetPointerOut: &pointer,
                parameterSetSizeOut: &size, parameterSetCountOut: nil, nalUnitHeaderLengthOut: nil
            )
            guard result == noErr, let pointer else { return nil }
            output.append(startCode)
            output.append(UnsafeBufferPointer(start: pointer, count: size))
        }
        return output
    }

    static func annexB(from sampleBuffer: CMSampleBuffer) -> Data? {
        guard let block = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
        var totalLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        guard CMBlockBufferGetDataPointer(
            block, atOffset: 0, lengthAtOffsetOut: nil,
            totalLengthOut: &totalLength, dataPointerOut: &dataPointer
        ) == kCMBlockBufferNoErr, let dataPointer else {
            return nil
        }
        let bytes = UnsafeRawPointer(dataPointer).assumingMemoryBound(to: UInt8.self)
        var output = Data()
        var offset = 0
        while offset < totalLength - avccLengthBytes {
            var length: UInt32 = 0
            for byte in 0..<avccLengthBytes {
                length = (length << 8) | UInt32(bytes[offset + byte])
            }
            offset += avccLengthBytes
            guard offset + Int(length) <= totalLength else { break }
            output.append(startCode)
            output.append(UnsafeBufferPointer(start: bytes + offset, count: Int(length)))
            offset += Int(length)
        }
        return output
    }

    static func isKeyframe(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer, createIfNecessary: false
        ) as? [[CFString: Any]], let first = attachments.first else {
            return true
        }
        let notSync = first[kCMSampleAttachmentKey_NotSync] as? Bool ?? false
        return !notSync
    }

    private static let avccLengthBytes = 4
}
