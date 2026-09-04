import SwiftUI
import SwiftData
import PhotosUI

/// Manual card entry form with live visual card preview and dynamic type-specific fields.
struct ManualEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]

    var existingCard: CardItem?
    var onSave: (() -> Void)? = nil

    @State private var cardType: CardType = .creditDebit
    @State private var displayName: String = ""
    @State private var cardNumber: String = ""
    @State private var expiryDate: String = ""
    @State private var cardholderName: String = ""
    @State private var secondaryField: String = ""
    @State private var notes: String = ""
    @State private var barcodeData: String = ""
    @State private var barcodeFormat: BarcodeFormat = .qr
    @State private var hasBarcodeData: Bool = false
    @State private var colorHex: String = "#1E1B4B"
    @State private var selectedCategory: Category?

    // Image picking
    @State private var frontPhotoItem: PhotosPickerItem?
    @State private var backPhotoItem: PhotosPickerItem?
    @State private var frontImageData: Data?
    @State private var backImageData: Data?

    var isEditing: Bool { existingCard != nil }
    private var config: CardTypeConfig { CardTypeConfig.config(for: cardType) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Live Card Preview
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("LIVE PREVIEW")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .tracking(1.2)

                                Spacer()

                                Text(config.badgeText)
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.white.opacity(0.1), in: Capsule())
                            }

                            CardVisualView(
                                type: cardType,
                                displayName: displayName,
                                cardNumber: cardNumber,
                                cardholderName: cardholderName,
                                expiryDate: expiryDate,
                                secondaryField: secondaryField,
                                colorHex: colorHex,
                                frontImageData: frontImageData,
                                barcodeData: hasBarcodeData ? barcodeData : nil,
                                barcodeFormat: hasBarcodeData ? barcodeFormat : nil,
                                categoryColor: selectedCategory?.color
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 4)

                        // MARK: - Card Type Selector
                        fieldSection("Card Type") {
                            Picker("Type", selection: $cardType) {
                                ForEach(CardType.allCases) { type in
                                    Label(type.displayName, systemImage: type.iconName).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // MARK: - Dynamic Card Details
                        fieldSection(config.badgeText) {
                            formField(config.displayNameLabel, text: $displayName, placeholder: config.displayNamePlaceholder)

                            formField(config.numberLabel, text: $cardNumber, placeholder: config.numberPlaceholder)
                                .keyboardType(config.numberKeyboard)
                                .onChange(of: cardNumber) { _, newValue in
                                    if cardType == .creditDebit {
                                        cardNumber = CardTypeConfig.formatNumber(newValue, for: .creditDebit)
                                    }
                                }

                            formField(config.holderLabel, text: $cardholderName, placeholder: config.holderPlaceholder)

                            HStack(spacing: 12) {
                                formField(config.expiryLabel, text: $expiryDate, placeholder: config.expiryPlaceholder)

                                formField(config.secondaryLabel, text: $secondaryField, placeholder: config.secondaryPlaceholder)
                                    .keyboardType(config.secondaryKeyboard)
                            }
                        }

                        // MARK: - Card Color & Theme
                        fieldSection("Card Theme Color") {
                            CardColorPicker(selectedHex: $colorHex)
                        }

                        // MARK: - Physical Card Photos
                        fieldSection("Card Images (Optional)") {
                            HStack(spacing: 12) {
                                imagePicker(
                                    label: "Front Photo",
                                    imageData: frontImageData,
                                    photoItem: $frontPhotoItem
                                )
                                imagePicker(
                                    label: "Back Photo",
                                    imageData: backImageData,
                                    photoItem: $backPhotoItem
                                )
                            }
                        }

                        // MARK: - Barcode / QR
                        fieldSection("Barcode & QR Code") {
                            Toggle("Include scannable barcode", isOn: $hasBarcodeData)
                                .tint(Color(hex: "#4F46E5"))
                                .foregroundStyle(.white)

                            if hasBarcodeData {
                                Picker("Format", selection: $barcodeFormat) {
                                    ForEach(BarcodeFormat.allCases) { format in
                                        Text(format.displayName).tag(format)
                                    }
                                }
                                .tint(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                formField("Barcode Encoded Data", text: $barcodeData, placeholder: "Data string to encode")
                            }
                        }

                        // MARK: - Category
                        if !categories.isEmpty {
                            fieldSection("Category") {
                                Picker("Category", selection: $selectedCategory) {
                                    Text("None").tag(Optional<Category>.none)
                                    ForEach(categories) { category in
                                        Label(category.name, systemImage: category.iconName)
                                            .tag(Optional(category))
                                    }
                                }
                                .tint(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // MARK: - Notes
                        fieldSection("Notes") {
                            TextField("Personal notes, PIN, or reminders…", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "#818CF8")!)
                }
            }
            .onChange(of: frontPhotoItem) { _, newItem in
                Task {
                    if let data = await loadPhoto(newItem) {
                        frontImageData = data
                    }
                }
            }
            .onChange(of: backPhotoItem) { _, newItem in
                Task {
                    if let data = await loadPhoto(newItem) {
                        backImageData = data
                    }
                }
            }
            .onChange(of: cardType) { oldType, newType in
                // If the user hasn't explicitly customized colors, adapt color to the new type
                if colorHex == oldType.defaultColor.toHex() || colorHex == "#1E1B4B" || colorHex == "#4F46E5" {
                    colorHex = newType.defaultColor.toHex()
                }
            }
            .onAppear {
                if let card = existingCard {
                    populateFrom(card)
                } else {
                    colorHex = cardType.defaultColor.toHex()
                }
            }
        }
    }

    // MARK: - Form Components

    private func fieldSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func formField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))

            TextField(placeholder, text: text)
                .foregroundStyle(.white)
                .padding(11)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        }
    }

    private func imagePicker(label: String, imageData: Data?, photoItem: Binding<PhotosPickerItem?>) -> some View {
        PhotosPicker(selection: photoItem, matching: .images) {
            VStack(spacing: 8) {
                if let data = imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(1.586, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.06))
                        .aspectRatio(1.586, contentMode: .fit)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                Text(label)
                                    .font(.caption)
                            }
                            .foregroundStyle(.white.opacity(0.4))
                        )
                }
            }
        }
    }

    // MARK: - Photo Loading

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem?) async -> Data? {
        guard let item = item else { return nil }
        do {
            return try await item.loadTransferable(type: Data.self)
        } catch {
            print("[ManualEntry] Photo load failed: \(error)")
            return nil
        }
    }

    // MARK: - Populate Existing

    private func populateFrom(_ card: CardItem) {
        cardType = card.cardType
        displayName = card.displayName
        cardNumber = card.cardNumber ?? ""
        expiryDate = card.expiryDate ?? ""
        cardholderName = card.cardholderName ?? ""
        secondaryField = card.secondaryField ?? ""
        notes = card.notes ?? ""
        colorHex = card.colorHex
        selectedCategory = card.category
        frontImageData = card.frontImageData
        backImageData = card.backImageData
        if let bd = card.barcodeData {
            hasBarcodeData = true
            barcodeData = bd
            barcodeFormat = card.barcodeFormat ?? .qr
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedNumber = cardNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveName = trimmedName.isEmpty ? config.displayNamePlaceholder.replacingOccurrences(of: "e.g. ", with: "") : trimmedName

        if let card = existingCard {
            // Update existing
            card.cardType = cardType
            card.displayName = effectiveName
            card.cardNumber = trimmedNumber.isEmpty ? nil : trimmedNumber
            card.expiryDate = expiryDate.isEmpty ? nil : expiryDate
            card.cardholderName = cardholderName.isEmpty ? nil : cardholderName
            card.secondaryField = secondaryField.isEmpty ? nil : secondaryField
            card.notes = notes.isEmpty ? nil : notes
            card.colorHex = colorHex
            card.category = selectedCategory
            card.frontImageData = frontImageData
            card.backImageData = backImageData
            card.barcodeData = hasBarcodeData && !barcodeData.isEmpty ? barcodeData : nil
            card.barcodeFormat = hasBarcodeData ? barcodeFormat : nil
            card.updatedAt = Date()
        } else {
            // Create new
            let card = CardItem(
                type: cardType,
                displayName: effectiveName,
                frontImageData: frontImageData,
                backImageData: backImageData,
                cardNumber: trimmedNumber.isEmpty ? nil : trimmedNumber,
                expiryDate: expiryDate.isEmpty ? nil : expiryDate,
                cardholderName: cardholderName.isEmpty ? nil : cardholderName,
                secondaryField: secondaryField.isEmpty ? nil : secondaryField,
                notes: notes.isEmpty ? nil : notes,
                barcodeData: hasBarcodeData && !barcodeData.isEmpty ? barcodeData : nil,
                barcodeFormat: hasBarcodeData ? barcodeFormat : nil,
                colorHex: colorHex,
                category: selectedCategory
            )
            modelContext.insert(card)
        }

        // Trigger callback to dismiss parent flow if provided
        onSave?()
        dismiss()
    }
}
