import Foundation

public enum SyncoJSON {
    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        return decoder
    }

    public static func encode(_ message: ControlMessage) throws -> Data {
        try makeEncoder().encode(message)
    }

    public static func decode(_ data: Data) throws -> ControlMessage {
        try makeDecoder().decode(ControlMessage.self, from: data)
    }

    public static func controlFrame(_ message: ControlMessage) throws -> FramePayload {
        .control(try encode(message))
    }

    public static func controlMessage(from payload: FramePayload) throws -> ControlMessage {
        guard payload.kind == .control else {
            throw SyncoError.malformedMessage(String(payload.kind.rawValue))
        }
        return try decode(payload.body)
    }
}
