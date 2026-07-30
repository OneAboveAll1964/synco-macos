import Foundation

public enum SyncoConstants {
    public static let protocolVersion = 1
    public static let serviceName = "synco"
}

extension SyncoConstants {
    public enum Discovery {
        public static let serviceType = "_synco._tcp"
        public static let domain = "local."
        public static let txtKeyVersion = "v"
        public static let txtKeyDeviceID = "did"
        public static let txtKeyDisplayName = "dn"
        public static let txtKeyPlatform = "pl"
        public static let txtKeyFingerprint = "fp"
        public static let displayNameMaxBytes = 63
    }

    public enum Framing {
        public static let lengthPrefixBytes = 4
        public static let maxPayloadBytes = 1_048_576
        public static let maxBlobChunkBytes = 262_144
        public static let transferIDBytes = 16
        public static let offsetBytes = 8
        public static let blobChunkHeaderBytes = transferIDBytes + offsetBytes
    }

    public enum Identity {
        public static let publicKeyBytes = 32
        public static let privateKeyBytes = 32
        public static let deviceIDCharacters = 16
        public static let deviceIDDigestPrefixBytes = 10
        public static let fingerprintDigestPrefixBytes = 8
        public static let fingerprintCharacters = 16
        public static let fingerprintGroupSize = 4
        public static let fingerprintGroupSeparator = "-"
    }

    public enum Handshake {
        public static let hkdfInfoString = "synco-v1-session"
        public static let hkdfInfo = Data(hkdfInfoString.utf8)
        public static let confirmationPrefixString = "synco-v1-confirm"
        public static let confirmationPrefix = Data(confirmationPrefixString.utf8)
        public static let sharedSecretBytes = 32
        public static let inputKeyMaterialBytes = 96
        public static let keyMaterialBytes = 64
        public static let sessionKeyBytes = 32
        public static let saltBytes = 32
        public static let confirmationTagBytes = 32
    }

    public enum Record {
        public static let nonceBytes = 12
        public static let noncePrefixBytes = 4
        public static let counterBytes = 8
        public static let authenticationTagBytes = 16
    }

    public enum Canonical {
        public static let unitSeparator: UInt8 = 0x1F
        public static let recordSeparator: UInt8 = 0x1E
        public static let escape: UInt8 = 0x1D
    }

    public enum Limits {
        public static let inlineRepresentationMaxBytes = 65_536
        public static let defaultMaxBlobBytes: Int64 = 104_857_600
        public static let suppressionWindowEntries = 32
    }

    public enum Timing {
        public static let pingIntervalSeconds: TimeInterval = 15
        public static let readTimeoutSeconds: TimeInterval = 45
        public static let pairTimeoutSeconds: TimeInterval = 120
        public static let reconnectBackoffBaseSeconds: TimeInterval = 1
        public static let reconnectBackoffCapSeconds: TimeInterval = 30
        public static let reconnectBackoffFactor: Double = 2
        public static let suppressionWindowSeconds: TimeInterval = 10
        public static var pingInterval: Duration { .seconds(pingIntervalSeconds) }
        public static var readTimeout: Duration { .seconds(readTimeoutSeconds) }
        public static var pairTimeout: Duration { .seconds(pairTimeoutSeconds) }
        public static var reconnectBackoffBase: Duration { .seconds(reconnectBackoffBaseSeconds) }
        public static var reconnectBackoffCap: Duration { .seconds(reconnectBackoffCapSeconds) }
        public static var suppressionWindow: Duration { .seconds(suppressionWindowSeconds) }
    }
}
