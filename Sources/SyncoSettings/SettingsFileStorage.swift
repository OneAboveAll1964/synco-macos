import Foundation
import SyncoCore

public struct SettingsFileStorage: Sendable {
    public let location: SettingsLocation

    public init(location: SettingsLocation = .default) {
        self.location = location
    }

    public func load() throws -> SettingsDocument? {
        guard FileManager.default.fileExists(atPath: location.fileURL.path(percentEncoded: false)) else {
            return nil
        }
        let data = try Data(contentsOf: location.fileURL)
        guard !data.isEmpty else { return nil }
        return try Self.makeDecoder().decode(SettingsDocument.self, from: data)
    }

    public func loadOrDefault() -> SettingsDocument {
        do {
            if let document = try load() { return document }
        } catch {
            SyncoLog.settings.error("settings load failed: \(error.localizedDescription, privacy: .public)")
        }
        return SettingsDocument.makeDefault()
    }

    public func save(_ document: SettingsDocument) throws {
        try FileManager.default.createDirectory(
            at: location.directoryURL,
            withIntermediateDirectories: true
        )
        let data = try Self.makeEncoder().encode(document)
        try data.write(to: location.fileURL, options: [.atomic])
    }

    public func remove() throws {
        guard FileManager.default.fileExists(atPath: location.fileURL.path(percentEncoded: false)) else {
            return
        }
        try FileManager.default.removeItem(at: location.fileURL)
    }

    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
