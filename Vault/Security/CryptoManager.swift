import Foundation
import CryptoKit

/// Handles AES-256-GCM encryption/decryption for backup files.
/// Uses HKDF key derivation from user-supplied passphrases.
enum CryptoManager {

    /// Encrypts data with AES-256-GCM using a passphrase-derived key.
    /// - Parameters:
    ///   - data: The plaintext data to encrypt.
    ///   - passphrase: User-supplied passphrase for key derivation.
    /// - Returns: Combined data: salt (32 bytes) + nonce (12 bytes) + ciphertext + tag.
    static func encrypt(_ data: Data, passphrase: String) throws -> Data {
        let salt = generateSalt()
        let key = deriveKey(from: passphrase, salt: salt)
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)

        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }

        // Prepend salt so we can re-derive the key on import
        return salt + combined
    }

    /// Decrypts data that was encrypted with `encrypt(_:passphrase:)`.
    /// - Parameters:
    ///   - data: The encrypted data (salt + nonce + ciphertext + tag).
    ///   - passphrase: The passphrase used during encryption.
    /// - Returns: The decrypted plaintext data.
    static func decrypt(_ data: Data, passphrase: String) throws -> Data {
        guard data.count > 32 else {
            throw CryptoError.invalidData
        }

        let salt = data.prefix(32)
        let sealedData = data.dropFirst(32)

        let key = deriveKey(from: passphrase, salt: Data(salt))
        let sealedBox = try AES.GCM.SealedBox(combined: sealedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Key derivation

    private static func deriveKey(from passphrase: String, salt: Data) -> SymmetricKey {
        let inputKey = SymmetricKey(data: Data(passphrase.utf8))
        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: salt,
            info: Data("com.vault.backup".utf8),
            outputByteCount: 32
        )
        return derived
    }

    private static func generateSalt(length: Int = 32) -> Data {
        var salt = Data(count: length)
        _ = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        return salt
    }

    // MARK: - Errors

    enum CryptoError: LocalizedError {
        case encryptionFailed
        case invalidData

        var errorDescription: String? {
            switch self {
            case .encryptionFailed: return "Encryption failed."
            case .invalidData:      return "Invalid encrypted data."
            }
        }
    }
}
