import SwiftUI
import SwiftData

/// Detail view for a single card, with 3D flip at the top and editable metadata below.
struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: CardItem

    @State private var isShowingBack: Bool = false
    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showBarcodeDisplay: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 3D Card
                        Card3DView(
                            frontImage: card.frontImageData.flatMap { UIImage(data: $0) },
                            backImage: card.backImageData.flatMap { UIImage(data: $0) },
                            cardColor: card.color,
                            isShowingBack: $isShowingBack
                        )
                        .frame(height: 260)
                        .padding(.horizontal, 20)

                        // Flip hint
                        HStack(spacing: 6) {
                            Image(systemName: "hand.draw.fill")
                                .font(.caption2)
                            Text(isShowingBack ? "Showing Back" : "Drag to flip")
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.4))

                        // Quick actions
                        HStack(spacing: 16) {
                            if card.barcodeData != nil {
                                quickActionButton(icon: "barcode", label: "Barcode") {
                                    showBarcodeDisplay = true
                                }
                            }

                            quickActionButton(icon: isShowingBack ? "rectangle.portrait" : "rectangle.portrait.rotate", label: "Flip") {
                                withAnimation {
                                    isShowingBack.toggle()
                                }
                            }

                            quickActionButton(icon: "square.and.pencil", label: "Edit") {
                                isEditing = true
                            }
                        }
                        .padding(.horizontal, 20)

                        // Card details
                        let config = CardTypeConfig.config(for: card.cardType)

                        VStack(spacing: 0) {
                            detailRow(label: "Type", value: card.cardType.displayName, icon: card.iconName)

                            if let number = card.cardNumber, !number.isEmpty {
                                detailRow(label: config.numberLabel, value: formatCardNumber(number), isSensitive: true)
                            }

                            if let name = card.cardholderName, !name.isEmpty {
                                detailRow(label: config.holderLabel, value: name)
                            }

                            if let expiry = card.expiryDate, !expiry.isEmpty {
                                detailRow(label: config.expiryLabel, value: expiry, isSensitive: true)
                            }

                            if let secondary = card.secondaryField, !secondary.isEmpty {
                                detailRow(label: config.secondaryLabel, value: secondary, isSensitive: card.cardType == .creditDebit)
                            }

                            if let notes = card.notes, !notes.isEmpty {
                                detailRow(label: "Notes", value: notes)
                            }

                            if let category = card.category {
                                detailRow(label: "Category", value: category.name, icon: category.iconName)
                            }

                            detailRow(label: "Added", value: card.createdAt.formatted(date: .abbreviated, time: .shortened), isLast: true)
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)

                        // Delete button
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Card", systemImage: "trash")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(card.displayName.isEmpty ? card.cardType.displayName : card.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .sheet(isPresented: $isEditing) {
                ManualEntryView(existingCard: card, onSave: {
                    isEditing = false
                })
            }
            .sheet(isPresented: $showBarcodeDisplay) {
                if let barcodeData = card.barcodeData, let format = card.barcodeFormat {
                    BarcodeDisplayView(data: barcodeData, format: format, cardName: card.displayName)
                }
            }
            .confirmationDialog("Delete Card", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(card)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This card will be permanently deleted.")
            }
        }
    }

    // MARK: - Components

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func detailRow(label: String, value: String, icon: String? = nil, isSensitive: Bool = false, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 90, alignment: .leading)

                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                if isSensitive {
                    SensitiveText(
                        text: value,
                        font: .subheadline.monospaced(),
                        foregroundStyle: AnyShapeStyle(.white)
                    )
                } else {
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if !isLast {
                Divider()
                    .background(.white.opacity(0.1))
                    .padding(.leading, 16)
            }
        }
    }

    private func formatCardNumber(_ number: String) -> String {
        var formatted = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return formatted
    }
}
