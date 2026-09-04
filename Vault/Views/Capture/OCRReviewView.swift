import SwiftUI
import SwiftData

/// Shows OCR-extracted fields from the captured card images, letting the user review and correct before saving.
struct OCRReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let frontImage: UIImage
    let backImage: UIImage?
    var onSave: (() -> Void)?

    @State private var cardType: CardType = .creditDebit
    @State private var displayName: String = ""
    @State private var cardNumber: String = ""
    @State private var expiryDate: String = ""
    @State private var cardholderName: String = ""
    @State private var notes: String = ""
    @State private var colorHex: String = "#4F46E5"
    @State private var isProcessing: Bool = true
    @State private var ocrConfidence: Float = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                if isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Analyzing card…")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Preview images
                            HStack(spacing: 12) {
                                imagePreview(frontImage, label: "Front")
                                if let backImage = backImage {
                                    imagePreview(backImage, label: "Back")
                                }
                            }
                            .padding(.horizontal, 20)

                            // OCR confidence
                            if ocrConfidence > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: ocrConfidence > 0.7 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundStyle(ocrConfidence > 0.7 ? .green : .orange)
                                    Text("OCR confidence: \(Int(ocrConfidence * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }

                            // Editable fields
                            VStack(spacing: 16) {
                                fieldSection("Card Details") {
                                    Picker("Type", selection: $cardType) {
                                        ForEach(CardType.allCases) { type in
                                            Text(type.displayName).tag(type)
                                        }
                                    }
                                    .tint(.white)

                                    formField("Display Name", text: $displayName, placeholder: "e.g. My Visa Card")
                                    formField("Card Number", text: $cardNumber, placeholder: "1234 5678 9012 3456")
                                        .keyboardType(.numberPad)
                                    formField("Expiry Date", text: $expiryDate, placeholder: "MM/YY")
                                    formField("Cardholder Name", text: $cardholderName, placeholder: "John Doe")
                                }

                                fieldSection("Notes") {
                                    TextField("Additional notes…", text: $notes, axis: .vertical)
                                        .lineLimit(3...6)
                                        .foregroundStyle(.white)
                                        .padding(12)
                                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                                }

                                fieldSection("Color") {
                                    CardColorPicker(selectedHex: $colorHex)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Review Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCard() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .disabled(isProcessing)
                }
            }
            .task {
                await runOCR()
            }
        }
    }

    // MARK: - Components

    private func imagePreview(_ image: UIImage, label: String) -> some View {
        VStack(spacing: 6) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(1.586, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.3), radius: 8)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private func fieldSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))

            VStack(spacing: 10) {
                content()
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func formField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
            TextField(placeholder, text: text)
                .foregroundStyle(.white)
                .padding(10)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - OCR

    private func runOCR() async {
        defer { isProcessing = false }

        do {
            let result = try await OCRService.recognizeText(in: frontImage)
            await MainActor.run {
                if let number = result.cardNumber { cardNumber = number }
                if let expiry = result.expiryDate { expiryDate = expiry }
                if let name = result.cardholderName { cardholderName = name }
                ocrConfidence = result.confidence
            }

            // Also process back image if available
            if let backImage = backImage {
                let backResult = try await OCRService.recognizeText(in: backImage)
                await MainActor.run {
                    // Append any notes from the back
                    if !backResult.allText.isEmpty {
                        notes = backResult.allText
                    }
                }
            }
        } catch {
            print("[OCRReview] OCR failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Save

    private func saveCard() {
        let card = CardItem(
            type: cardType,
            displayName: displayName,
            frontImageData: frontImage.jpegData(compressionQuality: 0.8),
            backImageData: backImage?.jpegData(compressionQuality: 0.8),
            cardNumber: cardNumber.isEmpty ? nil : cardNumber,
            expiryDate: expiryDate.isEmpty ? nil : expiryDate,
            cardholderName: cardholderName.isEmpty ? nil : cardholderName,
            notes: notes.isEmpty ? nil : notes,
            colorHex: colorHex
        )

        modelContext.insert(card)
        onSave?()
        dismiss()
    }
}
