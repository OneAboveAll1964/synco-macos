import Foundation
import Security
import SyncoCore

public struct IdentityKeychainStore: Sendable {
    public static let defaultService = "com.shkomaghdid.synco.macos.identity"
    public static let defaultAccount = "static-x25519-v1"

    private let service: String
    private let account: String

    public init(service: String = defaultService, account: String = defaultAccount) {
        self.service = service
        self.account = account
    }

    public func loadOrCreate() throws -> DeviceIdentity {
        if let existing = try load() { return existing }
        let identity = try DeviceIdentity.generate()
        let status = add(identity.privateKey)
        switch status {
        case errSecSuccess:
            return identity
        case errSecDuplicateItem:
            guard let existing = try load() else { throw SyncoError.keychain(status: status) }
            return existing
        default:
            throw SyncoError.keychain(status: status)
        }
    }

    public func load() throws -> DeviceIdentity? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let representation = item as? Data else {
                throw SyncoError.invalidIdentityKey
            }
            return try DeviceIdentity(privateKeyRepresentation: representation)
        case errSecItemNotFound:
            return nil
        default:
            throw SyncoError.keychain(status: status)
        }
    }

    public func remove() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SyncoError.keychain(status: status)
        }
    }

    public func replaceWithFreshIdentity() throws -> DeviceIdentity {
        try remove()
        return try loadOrCreate()
    }

    private func add(_ representation: Data) -> OSStatus {
        var attributes = baseQuery()
        attributes[kSecValueData as String] = representation
        return SecItemAdd(attributes as CFDictionary, nil)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
