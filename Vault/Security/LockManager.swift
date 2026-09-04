import Foundation
import SwiftUI

/// Manages the app's lock/unlock state, idle timeout, and sensitive-mode toggle.
@Observable
@MainActor
final class LockManager {
    // MARK: - State
    var isLocked: Bool = true
    var isShowingPasscodeEntry: Bool = false

    // MARK: - Settings (persisted via AppStorage in views)
    var autoLockInterval: TimeInterval = 0   // 0 = immediately on background
    var isSensitiveModeEnabled: Bool = false

    // MARK: - Internal
    private var lastActiveDate: Date = Date()

    static let shared = LockManager()
    private init() {
        let hasSecurity = KeychainManager.shared.hasPasscode || BiometricAuthManager.shared.isBiometricAvailable
        self.isLocked = hasSecurity
    }

    // MARK: - Auto-lock intervals

    enum AutoLockOption: Double, CaseIterable, Identifiable {
        case immediately = 0
        case thirtySeconds = 30
        case oneMinute = 60
        case fiveMinutes = 300
        case fifteenMinutes = 900

        var id: Double { rawValue }

        var displayName: String {
            switch self {
            case .immediately:    return "Immediately"
            case .thirtySeconds:  return "30 seconds"
            case .oneMinute:      return "1 minute"
            case .fiveMinutes:    return "5 minutes"
            case .fifteenMinutes: return "15 minutes"
            }
        }
    }

    // MARK: - Scene phase handling

    /// Call when the app moves to background or inactive.
    func appDidEnterBackground() {
        lastActiveDate = Date()
        if autoLockInterval == 0 {
            lock()
        }
    }

    /// Call when the app becomes active. Locks if idle timeout has elapsed.
    func appDidBecomeActive() {
        let elapsed = Date().timeIntervalSince(lastActiveDate)
        if autoLockInterval > 0 && elapsed >= autoLockInterval {
            lock()
        }
    }

    // MARK: - Lock / Unlock

    func lock() {
        isLocked = true
        isShowingPasscodeEntry = false
    }

    func unlock() {
        isLocked = false
        isShowingPasscodeEntry = false
        lastActiveDate = Date()
    }

    /// Attempt biometric unlock, falling back to passcode entry UI.
    func attemptBiometricUnlock() async {
        let success = await BiometricAuthManager.shared.authenticate()
        await MainActor.run {
            if success {
                unlock()
            } else {
                isShowingPasscodeEntry = true
            }
        }
    }
}
