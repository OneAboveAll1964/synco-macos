import Foundation
import Network
import SyncoCore

private typealias Keys = SyncoConstants.Discovery

public enum TXTRecordCodec {
    public static func entries(for advertisement: ServiceAdvertisement) -> [String: String] {
        [
            Keys.txtKeyVersion: String(advertisement.version),
            Keys.txtKeyDeviceID: advertisement.deviceID.rawValue,
            Keys.txtKeyDisplayName: DisplayNameEncoder.truncated(advertisement.displayName),
            Keys.txtKeyPlatform: advertisement.platform.rawValue,
            Keys.txtKeyFingerprint: advertisement.fingerprint.compact,
        ]
    }

    public static func advertisement(from entries: [String: String]) throws -> ServiceAdvertisement {
        guard let versionText = entries[Keys.txtKeyVersion], let version = Int(versionText) else {
            throw SyncoError.malformedMessage(Keys.txtKeyVersion)
        }
        guard version == SyncoConstants.protocolVersion else {
            throw SyncoError.versionMismatch(version)
        }
        guard let deviceIDText = entries[Keys.txtKeyDeviceID] else {
            throw SyncoError.malformedMessage(Keys.txtKeyDeviceID)
        }
        guard let platformText = entries[Keys.txtKeyPlatform],
              let platform = DevicePlatform(rawValue: platformText)
        else {
            throw SyncoError.malformedMessage(Keys.txtKeyPlatform)
        }
        guard let fingerprintText = entries[Keys.txtKeyFingerprint] else {
            throw SyncoError.malformedMessage(Keys.txtKeyFingerprint)
        }
        let deviceID = try DeviceID(validating: deviceIDText)
        let displayName = entries[Keys.txtKeyDisplayName].flatMap { $0.isEmpty ? nil : $0 }
        return ServiceAdvertisement(
            deviceID: deviceID,
            displayName: displayName ?? deviceID.rawValue,
            platform: platform,
            fingerprint: try Fingerprint(parsing: fingerprintText),
            version: version
        )
    }

    public static func txtRecord(for advertisement: ServiceAdvertisement) -> NWTXTRecord {
        NWTXTRecord(entries(for: advertisement))
    }

    public static func advertisement(from record: NWTXTRecord) throws -> ServiceAdvertisement {
        try advertisement(from: record.dictionary)
    }
}
