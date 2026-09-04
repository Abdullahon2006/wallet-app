import SwiftUI

/// View for creating or changing the 6-digit passcode.
struct PasscodeSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var step: SetupStep = .enter
    @State private var firstEntry: String = ""
    @State private var secondEntry: String = ""
    @State private var currentInput: String = ""
    @State private var showError: Bool = false

    let isChanging: Bool
    var onComplete: (() -> Void)?

    enum SetupStep {
        case enter, confirm
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Title
                    VStack(spacing: 8) {
                        Text(step == .enter ? "Enter New Passcode" : "Confirm Passcode")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("Choose a 6-digit passcode")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    // Dots
                    HStack(spacing: 16) {
                        ForEach(0..<6, id: \.self) { index in
                            Circle()
                                .fill(index < currentInput.count ? Color.white : Color.white.opacity(0.2))
                                .frame(width: 14, height: 14)
                                .scaleEffect(index < currentInput.count ? 1.2 : 1.0)
                                .animation(.spring(response: 0.2), value: currentInput.count)
                        }
                    }
                    .modifier(ShakeEffect(shakes: showError ? 3 : 0))
                    .animation(.easeInOut(duration: 0.4), value: showError)

                    if showError {
                        Text("Passcodes don't match. Try again.")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.9))
                    }

                    // Number pad
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                        ForEach(1...9, id: \.self) { digit in
                            passcodeButton(String(digit))
                        }
                        Color.clear.frame(width: 72, height: 72)
                        passcodeButton("0")
                        Button {
                            if !currentInput.isEmpty { currentInput.removeLast() }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 72, height: 72)
                                Image(systemName: "delete.left.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        }
                    }

                    Spacer()
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private func passcodeButton(_ digit: String) -> some View {
        Button {
            appendDigit(digit)
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 72, height: 72)
                Text(digit)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    private func appendDigit(_ digit: String) {
        guard currentInput.count < 6 else { return }
        currentInput += digit
        showError = false

        if currentInput.count == 6 {
            handleComplete()
        }
    }

    private func handleComplete() {
        switch step {
        case .enter:
            firstEntry = currentInput
            currentInput = ""
            withAnimation(.spring(response: 0.3)) {
                step = .confirm
            }

        case .confirm:
            if currentInput == firstEntry {
                KeychainManager.shared.setPasscode(firstEntry)
                onComplete?()
                dismiss()
            } else {
                withAnimation {
                    showError = true
                }
                currentInput = ""
                secondEntry = ""
                step = .enter
                firstEntry = ""
            }
        }
    }
}
