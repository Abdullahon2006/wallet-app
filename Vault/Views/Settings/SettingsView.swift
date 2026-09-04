import SwiftUI
import SwiftData

/// App settings: security, data management, and about.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var lockManager = LockManager.shared

    @AppStorage("autoLockInterval") private var autoLockInterval: Double = 0
    @AppStorage("sensitiveMode") private var sensitiveMode: Bool = false
    @AppStorage("useBiometrics") private var useBiometrics: Bool = true

    @State private var showPasscodeSetup: Bool = false
    @State private var showExport: Bool = false
    @State private var showImport: Bool = false
    @State private var showDeleteAllConfirmation: Bool = false

    @Query private var cards: [CardItem]
    @Query private var categories: [Category]

    private let biometricManager = BiometricAuthManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                List {
                    // MARK: - Security
                    Section {
                        // Passcode
                        Button {
                            showPasscodeSetup = true
                        } label: {
                            settingsRow(
                                icon: "lock.fill",
                                iconColor: "#4F46E5",
                                title: KeychainManager.shared.hasPasscode ? "Change Passcode" : "Set Passcode",
                                subtitle: KeychainManager.shared.hasPasscode ? "Passcode is set" : "No passcode configured"
                            )
                        }

                        // Biometrics
                        if biometricManager.isBiometricAvailable {
                            Toggle(isOn: $useBiometrics) {
                                settingsRow(
                                    icon: biometricManager.biometricIcon,
                                    iconColor: "#059669",
                                    title: biometricManager.biometricName,
                                    subtitle: "Unlock with \(biometricManager.biometricName)"
                                )
                            }
                            .tint(Color(hex: "#4F46E5"))
                        }

                        // Auto-lock
                        Picker(selection: $autoLockInterval) {
                            ForEach(LockManager.AutoLockOption.allCases) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        } label: {
                            settingsRow(
                                icon: "timer",
                                iconColor: "#EA580C",
                                title: "Auto-Lock",
                                subtitle: nil
                            )
                        }
                        .tint(.white.opacity(0.5))

                        // Sensitive mode
                        Toggle(isOn: $sensitiveMode) {
                            settingsRow(
                                icon: "eye.slash.fill",
                                iconColor: "#E11D48",
                                title: "Sensitive Mode",
                                subtitle: "Blur card numbers in list view"
                            )
                        }
                        .tint(Color(hex: "#4F46E5"))
                    } header: {
                        Text("Security")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                    .listRowSeparatorTint(.white.opacity(0.08))

                    // MARK: - Data
                    Section {
                        Button {
                            showExport = true
                        } label: {
                            settingsRow(
                                icon: "square.and.arrow.up.fill",
                                iconColor: "#7C3AED",
                                title: "Export Backup",
                                subtitle: "\(cards.count) cards, \(categories.count) categories"
                            )
                        }

                        Button {
                            showImport = true
                        } label: {
                            settingsRow(
                                icon: "square.and.arrow.down.fill",
                                iconColor: "#0D9488",
                                title: "Import Backup",
                                subtitle: "Restore from .vaultbackup file"
                            )
                        }

                        Button(role: .destructive) {
                            showDeleteAllConfirmation = true
                        } label: {
                            settingsRow(
                                icon: "trash.fill",
                                iconColor: "#DC2626",
                                title: "Delete All Data",
                                subtitle: "Permanently remove all cards"
                            )
                        }
                    } header: {
                        Text("Data")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                    .listRowSeparatorTint(.white.opacity(0.08))

                    // MARK: - About
                    Section {
                        settingsRow(
                            icon: "info.circle.fill",
                            iconColor: "#475569",
                            title: "Version",
                            subtitle: "1.0.0"
                        )

                        settingsRow(
                            icon: "doc.text.fill",
                            iconColor: "#475569",
                            title: "License",
                            subtitle: "MIT"
                        )

                        settingsRow(
                            icon: "shield.checkered",
                            iconColor: "#475569",
                            title: "Privacy",
                            subtitle: "All data stays on this device"
                        )
                    } header: {
                        Text("About")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                    .listRowSeparatorTint(.white.opacity(0.08))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPasscodeSetup) {
                PasscodeSetupView(isChanging: KeychainManager.shared.hasPasscode)
            }
            .sheet(isPresented: $showExport) {
                ExportView()
            }
            .sheet(isPresented: $showImport) {
                ImportView()
            }
            .confirmationDialog("Delete All Data", isPresented: $showDeleteAllConfirmation) {
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all cards and categories. This action cannot be undone.")
            }
            .onChange(of: sensitiveMode) { _, newValue in
                lockManager.isSensitiveModeEnabled = newValue
            }
            .onChange(of: autoLockInterval) { _, newValue in
                lockManager.autoLockInterval = newValue
            }
        }
    }

    private func settingsRow(icon: String, iconColor: String, title: String, subtitle: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background((Color(hex: iconColor) ?? .gray).opacity(0.8), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: CardItem.self)
            try modelContext.delete(model: Category.self)
        } catch {
            print("[Settings] Delete all failed: \(error)")
        }
    }
}
