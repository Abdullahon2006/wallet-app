import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Import view — decrypts and restores a .vaultbackup file.
struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showFilePicker: Bool = false
    @State private var selectedFileData: Data?
    @State private var selectedFileName: String?
    @State private var passphrase: String = ""
    @State private var isImporting: Bool = false
    @State private var errorMessage: String?
    @State private var importSummary: BackupService.ImportSummary?
    @State private var showSuccess: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // File selection
                        VStack(spacing: 16) {
                            if let fileName = selectedFileName {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color(hex: "#4F46E5")!)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(fileName)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.white)

                                        if let data = selectedFileData {
                                            Text(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.5))
                                        }
                                    }

                                    Spacer()

                                    Button {
                                        selectedFileData = nil
                                        selectedFileName = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                }
                                .padding(16)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            } else {
                                Button {
                                    showFilePicker = true
                                } label: {
                                    VStack(spacing: 12) {
                                        Image(systemName: "doc.badge.arrow.up.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(Color(hex: "#4F46E5")!)

                                        Text("Select Backup File")
                                            .font(.headline)
                                            .foregroundStyle(.white)

                                        Text(".vaultbackup files only")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                            .foregroundStyle(.white.opacity(0.15))
                                    )
                                }
                            }
                        }

                        // Passphrase
                        if selectedFileData != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Backup Passphrase")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.6))

                                SecureField("Enter the passphrase used during export", text: $passphrase)
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        if let errorMessage = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }

                        // Import button
                        if selectedFileData != nil {
                            Button {
                                performImport()
                            } label: {
                                if isImporting {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                } else {
                                    Label("Import Backup", systemImage: "square.and.arrow.down")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                }
                            }
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#059669")!, Color(hex: "#0D9488")!],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .disabled(!canImport)
                            .opacity(canImport ? 1 : 0.5)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Import Complete", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                if let summary = importSummary {
                    Text("Imported \(summary.cardsImported) cards and \(summary.categoriesImported) categories from backup created on \(summary.exportedAt.formatted(date: .abbreviated, time: .omitted)).")
                }
            }
        }
    }

    private var canImport: Bool {
        selectedFileData != nil && !passphrase.isEmpty && !isImporting
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                selectedFileData = try Data(contentsOf: url)
                selectedFileName = url.lastPathComponent
            } catch {
                errorMessage = "Could not read the selected file."
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func performImport() {
        guard let data = selectedFileData else { return }
        isImporting = true
        errorMessage = nil

        Task {
            do {
                let summary = try BackupService.shared.importBackup(
                    data: data,
                    passphrase: passphrase,
                    modelContext: modelContext
                )
                await MainActor.run {
                    importSummary = summary
                    isImporting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Import failed. Check your passphrase and try again."
                    isImporting = false
                }
            }
        }
    }
}
