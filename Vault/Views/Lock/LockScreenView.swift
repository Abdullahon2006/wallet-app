import SwiftUI

/// The lock screen shown when the app is locked.
/// Supports biometric unlock + passcode fallback.
struct LockScreenView: View {
    @State private var lockManager = LockManager.shared
    @State private var passcodeInput: String = ""
    @State private var showError: Bool = false
    @State private var isAuthenticating: Bool = false
    @State private var animateUnlock: Bool = false

    private let biometricManager = BiometricAuthManager.shared
    private let keychainManager = KeychainManager.shared

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.15),
                    Color(red: 0.10, green: 0.08, blue: 0.22),
                    Color(red: 0.05, green: 0.05, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Vault icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)

                    Image(systemName: animateUnlock ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.symbolEffect(.replace))
                }
                .scaleEffect(isAuthenticating ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isAuthenticating)

                VStack(spacing: 8) {
                    Text("Vault")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Your cards, secured locally")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                if lockManager.isShowingPasscodeEntry {
                    passcodeEntryView
                } else {
                    biometricPromptView
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            attemptBiometric()
        }
    }

    // MARK: - Biometric prompt

    private var biometricPromptView: some View {
        VStack(spacing: 20) {
            if biometricManager.isBiometricAvailable {
                Button {
                    attemptBiometric()
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: biometricManager.biometricIcon)
                            .font(.system(size: 36))
                            .foregroundStyle(.white)

                        Text("Tap to unlock with \(biometricManager.biometricName)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }

            if keychainManager.hasPasscode {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        lockManager.isShowingPasscodeEntry = true
                    }
                } label: {
                    Text("Use Passcode")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(.white.opacity(0.1), in: Capsule())
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Passcode entry

    private var passcodeEntryView: some View {
        VStack(spacing: 20) {
            // Passcode dots
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < passcodeInput.count ? Color.white : Color.white.opacity(0.2))
                        .frame(width: 14, height: 14)
                        .scaleEffect(index < passcodeInput.count ? 1.2 : 1.0)
                        .animation(.spring(response: 0.2), value: passcodeInput.count)
                }
            }
            .modifier(ShakeEffect(shakes: showError ? 3 : 0))
            .animation(.easeInOut(duration: 0.4), value: showError)

            if showError {
                Text("Incorrect passcode")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.9))
                    .transition(.opacity)
            }

            // Number pad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(1...9, id: \.self) { digit in
                    numberButton(String(digit))
                }
                // Bottom row
                numberButton("", systemImage: "delete.left.fill", action: {
                    if !passcodeInput.isEmpty { passcodeInput.removeLast() }
                })
                numberButton("0")
                numberButton("", systemImage: biometricManager.biometricIcon, action: {
                    withAnimation { lockManager.isShowingPasscodeEntry = false }
                    attemptBiometric()
                })
            }
            .padding(.top, 8)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func numberButton(_ digit: String, systemImage: String? = nil, action: (() -> Void)? = nil) -> some View {
        Button {
            if let action = action {
                action()
            } else {
                appendDigit(digit)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 72, height: 72)

                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(.white)
                } else {
                    Text(digit)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Actions

    private func appendDigit(_ digit: String) {
        guard passcodeInput.count < 6 else { return }
        passcodeInput += digit
        showError = false

        if passcodeInput.count == 6 {
            verifyPasscode()
        }
    }

    private func verifyPasscode() {
        if keychainManager.verifyPasscode(passcodeInput) {
            withAnimation(.spring(response: 0.5)) {
                animateUnlock = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                lockManager.unlock()
            }
        } else {
            withAnimation {
                showError = true
            }
            passcodeInput = ""
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private func attemptBiometric() {
        guard biometricManager.isBiometricAvailable else {
            lockManager.isShowingPasscodeEntry = true
            return
        }

        isAuthenticating = true
        Task {
            await lockManager.attemptBiometricUnlock()
            await MainActor.run {
                isAuthenticating = false
            }
        }
    }
}

// MARK: - Shake effect for wrong passcode

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(animatableData * .pi * 2) * 10
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
