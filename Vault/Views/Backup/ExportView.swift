import SwiftUI
import SwiftData

/// Export view — creates an encrypted .vaultbackup file.
struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var passphrase: String = ""
    @State private var confirmPassphrase: String = ""
    @State private var isExporting: Bool = false
    @State private var exportedData: Data?
    @State private var showShareSheet: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccess: Bool = false

    @Query private var cards: [CardItem]
    @Query private var categories: [Category]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Info card
                        VStack(spacing: 12) {
                            Image(systemName: "lock.doc.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "#4F46E5")!, Color(hex: "#7C3AED")!],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Encrypted Backup")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)

                            Text("Your backup will be encrypted with the passphrase you set. Without this passphrase, the backup file cannot be read.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                        // Stats
                        HStack(spacing: 16) {
                            statBox(count: cards.count, label: "Cards")
                            statBox(count: categories.count, label: "Categories")
                        }

                        // Passphrase fields
                        VStack(spacing: 12) {
                            SecureField("Passphrase", text: $passphrase)
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

                            SecureField("Confirm Passphrase", text: $confirmPassphrase)
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

                            if passphrase != confirmPassphrase && !confirmPassphrase.isEmpty {
                                Text("Passphrases don't match")
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                        }

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(12)
                                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }

                        // Export button
                        Button {
                            performExport()
                        } label: {
                            if isExporting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            } else {
                                Label("Export Backup", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#4F46E5")!, Color(hex: "#7C3AED")!],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .disabled(!canExport)
                        .opacity(canExport ? 1 : 0.5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = exportedData {
                    ShareSheet(data: data, filename: "Vault_Backup_\(formattedDate).vaultbackup")
                }
            }
            .alert("Backup Created", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your encrypted backup is ready to save.")
            }
        }
    }

    private var canExport: Bool {
        !passphrase.isEmpty && passphrase == confirmPassphrase && !isExporting
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func statBox(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func performExport() {
        isExporting = true
        errorMessage = nil

        Task {
            do {
                let data = try BackupService.shared.exportBackup(
                    modelContext: modelContext,
                    passphrase: passphrase
                )
                await MainActor.run {
                    exportedData = data
                    isExporting = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Write data to a temporary file
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)

        let controller = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
