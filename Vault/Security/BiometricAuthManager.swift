import Foundation
import LocalAuthentication

/// Handles Face ID / Touch ID authentication.
final class BiometricAuthManager: @unchecked Sendable {
    static let shared = BiometricAuthManager()
    private init() {}

    /// The type of biometric available on this device.
    enum BiometricType {
        case faceID
        case touchID
        case none
    }

    /// Returns the available biometric type, or `.none` if unavailable.
    var availableBiometric: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID:  return .faceID
        case .touchID: return .touchID
        default:       return .none
        }
    }

    /// Whether biometric authentication is available.
    var isBiometricAvailable: Bool {
        availableBiometric != .none
    }

    /// Human-readable name for the biometric type.
    var biometricName: String {
        switch availableBiometric {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .none:    return "Biometrics"
        }
    }

    /// SF Symbol name for the biometric type.
    var biometricIcon: String {
        switch availableBiometric {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        case .none:    return "lock.fill"
        }
    }

    /// Attempts biometric authentication. Returns `true` on success.
    func authenticate(reason: String = "Unlock Vault") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            print("[BiometricAuth] Failed: \(error.localizedDescription)")
            return false
        }
    }
}
