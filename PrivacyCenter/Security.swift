import Foundation
import LocalAuthentication
import CryptoKit

enum SecurityError: Error {
    case authenticationFailed
    case invalidData
}

final class BiometricAuth {
    static let shared = BiometricAuth()

    func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw SecurityError.authenticationFailed
        }

        let ok = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )

        guard ok else { throw SecurityError.authenticationFailed }
    }
}

/// Chiffrement AES-GCM pour les fichiers stockés par l’app.
/// La clé est conservée dans le Keychain.
final class VaultCrypto {
    static let shared = VaultCrypto()
    private let service = "PrivacyCenter.VaultKey"

    private func key() throws -> SymmetricKey {
        if let data = KeychainStore.read(service: service) {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        KeychainStore.save(data, service: service)
        return key
    }

    func encrypt(_ data: Data) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: key())
        guard let combined = sealed.combined else { throw SecurityError.invalidData }
        return combined
    }

    func decrypt(_ data: Data) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key())
    }
}

enum KeychainStore {
    static func save(_ data: Data, service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(service: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else {
            return nil
        }
        return result as? Data
    }
}
