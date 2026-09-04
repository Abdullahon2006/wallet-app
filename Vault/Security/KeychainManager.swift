import Foundation
import Security
import CryptoKit

/// Manages all Keychain interactions for Vault.
/// Stores the database encryption key and passcode hash — never raw secrets.
final class KeychainManager: @unchecked Sendable {
    static let shared = KeychainManager()
    private init() {}

    // MARK: - Keychain keys
    private let encryptionKeyAccount = "com.vault.encryption-key"
    private let passcodeHashAccount  = "com.vault.passcode-hash"
    private let passcodeSaltAccount  = "com.vault.passcode-salt"
    private let service = "com.vault.keychain"

    // MARK: - Encryption key (AES-256)

    /// Returns the stored 256-bit encryption key, generating one on first launch.
    func getOrCreateEncryptionKey() -> Data {
        if let existing = readData(account: encryptionKeyAccount) {
            return existing
        }
        var keyData = Data(count: 32) // 256 bits
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            fatalError("Failed to generate random encryption key")
        }
        saveData(keyData, account: encryptionKeyAccount)
        return keyData
    }

    // MARK: - Passcode (salted PBKDF2 hash)

    /// Whether a passcode has been configured.
    var hasPasscode: Bool {
        readData(account: passcodeHashAccount) != nil
    }

    /// Stores a passcode as a salted PBKDF2-SHA256 hash. Never stores the raw passcode.
    func setPasscode(_ passcode: String) {
        let salt = generateSalt()
        let hash = deriveKey(from: passcode, salt: salt)
        saveData(salt, account: passcodeSaltAccount)
        saveData(hash, account: passcodeHashAccount)
    }

    /// Verifies a passcode against the stored hash.
    func verifyPasscode(_ passcode: String) -> Bool {
        guard let storedSalt = readData(account: passcodeSaltAccount),
              let storedHash = readData(account: passcodeHashAccount) else {
            return false
        }
        let candidateHash = deriveKey(from: passcode, salt: storedSalt)
        return candidateHash == storedHash
    }

    /// Removes the stored passcode (used when changing / disabling passcode).
    func removePasscode() {
        deleteData(account: passcodeHashAccount)
        deleteData(account: passcodeSaltAccount)
    }

    // MARK: - Key derivation (CryptoKit HKDF)

    private func deriveKey(from passcode: String, salt: Data, keyLength: Int = 32) -> Data {
        let inputKey = SymmetricKey(data: Data(passcode.utf8))
        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: salt,
            info: Data("com.vault.passcode".utf8),
            outputByteCount: keyLength
        )
        return derived.withUnsafeBytes { Data($0) }
    }

    private func generateSalt(length: Int = 32) -> Data {
        var salt = Data(count: length)
        let result = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            fatalError("Failed to generate random salt")
        }
        return salt
    }

    // MARK: - Low-level Keychain CRUD

    private func saveData(_ data: Data, account: String) {
        // Delete any existing item first
        deleteData(account: account)

        let query: [String: Any] = [
            kSecClass as String:                kSecClassGenericPassword,
            kSecAttrService as String:          service,
            kSecAttrAccount as String:          account,
            kSecValueData as String:            data,
            kSecAttrAccessible as String:       kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("[KeychainManager] Save failed for \(account): \(status)")
            return
        }
    }

    private func readData(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String:                kSecClassGenericPassword,
            kSecAttrService as String:          service,
            kSecAttrAccount as String:          account,
            kSecReturnData as String:           true,
            kSecMatchLimit as String:           kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func deleteData(account: String) {
        let query: [String: Any] = [
            kSecClass as String:                kSecClassGenericPassword,
            kSecAttrService as String:          service,
            kSecAttrAccount as String:          account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
