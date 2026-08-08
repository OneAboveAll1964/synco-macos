import Foundation
import SyncoCore
import SyncoCrypto

public struct QRPairingCode: Hashable, Sendable {
    public let payload: String
    public let token: String
    public let hosts: [String]
    public let port: UInt16
}

public enum QRPairing {

    public static func token() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URL()
    }

    public static func code(
        identity: DeviceIdentity,
        displayName: String,
        hosts: [String],
        port: UInt16,
        token: String = token()
    ) -> QRPairingCode? {
        guard !hosts.isEmpty, port > 0 else { return nil }
        var parts = URLComponents()
        parts.scheme = "synco"
        parts.host = "pair"
        parts.queryItems = [
            URLQueryItem(name: "v", value: "1"),
            URLQueryItem(name: "did", value: identity.deviceID.rawValue),
            URLQueryItem(name: "key", value: identity.publicKey.base64URL()),
            URLQueryItem(name: "fp", value: identity.fingerprint.grouped),
            URLQueryItem(name: "name", value: displayName),
            URLQueryItem(name: "port", value: String(port)),
            URLQueryItem(name: "hosts", value: hosts.joined(separator: ",")),
            URLQueryItem(name: "tok", value: token),
        ]
        guard let payload = parts.string else { return nil }
        return QRPairingCode(payload: payload, token: token, hosts: hosts, port: port)
    }
}

extension Data {
    func base64URL() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
