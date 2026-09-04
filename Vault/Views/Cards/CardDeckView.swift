import SwiftUI
import SwiftData

/// Display modes for viewing cards in the wallet deck.
enum DeckDisplayMode: String, CaseIterable {
    case walletStack = "Stack"
    case expandedList = "List"

    var iconName: String {
        switch self {
        case .walletStack:   return "rectangle.stack.fill"
        case .expandedList:  return "rectangle.grid.1x2.fill"
        }
    }
}

/// The main card deck view featuring authentic Apple Wallet-style cascading stack physics,
/// interactive tap-to-focus expansion, category filtering, and list view mode.
struct CardDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CardItem.updatedAt, order: .reverse) private var cards: [CardItem]
    @Query private var categories: [Category]

    @State private var searchText: String = ""
    @State private var selectedCategory: Category?
    @State private var showAddSheet: Bool = false
    @State private var selectedCard: CardItem?
    @State private var focusedCardId: UUID? = nil
    @State private var displayMode: DeckDisplayMode = .walletStack
    @State private var lockManager = LockManager.shared

    var filteredCards: [CardItem] {
        var result = cards

        if let category = selectedCategory {
            result = result.filter { $0.category?.id == category.id }
        }

        if !searchText.isEmpty {
            result = result.filter { card in
                card.displayName.localizedCaseInsensitiveContains(searchText) ||
                (card.cardholderName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (card.cardNumber?.contains(searchText) ?? false) ||
                card.cardType.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark luxurious background
                Color(red: 0.05, green: 0.05, blue: 0.11)
                    .ignoresSafeArea()

                if cards.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        // Category filter chips
                        if !categories.isEmpty {
                            categoryChips
                                .padding(.top, 4)
                                .padding(.bottom, 12)
                        }

                        // Cards Area
                        ScrollView {
                            if displayMode == .walletStack && searchText.isEmpty {
                                walletStackView
                                    .padding(.top, 12)
                                    .padding(.bottom, 120)
                            } else {
                                expandedListView
                                    .padding(.top, 8)
                                    .padding(.bottom, 100)
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search cards, numbers, or tags")
            .navigationTitle("Vault")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !cards.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                displayMode = (displayMode == .walletStack) ? .expandedList : .walletStack
                                focusedCardId = nil
                            }
                        } label: {
                            Image(systemName: displayMode.iconName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(7)
                                .background(.white.opacity(0.1), in: Circle())
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#818CF8")!, Color(hex: "#C084FC")!],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddCardFlowView(onCardAdded: {
                    showAddSheet = false
                })
            }
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card)
            }
        }
    }

    // MARK: - Apple Wallet Cascading Stack

    private var walletStackView: some View {
        let cardList = filteredCards
        let stackPeekHeight: CGFloat = 68
        let totalHeight: CGFloat = max(260, CGFloat(cardList.count) * stackPeekHeight + 220)

        return ZStack(alignment: .top) {
            ForEach(Array(cardList.enumerated()), id: \.element.id) { index, card in
                let isFocused = (focusedCardId == card.id)
                let yOffset = calculateCardOffset(index: index, focusedIndex: cardList.firstIndex(where: { $0.id == focusedCardId }))

                VStack(spacing: 8) {
                    CardRowView(card: card, isExpanded: isFocused)
                        .scaleEffect(isFocused ? 1.02 : 1.0)
                        .shadow(
                            color: isFocused ? card.color.opacity(0.45) : .black.opacity(0.35),
                            radius: isFocused ? 20 : 10,
                            x: 0,
                            y: isFocused ? 12 : 6
                        )
                        .onTapGesture {
                            handleCardTap(card: card)
                        }

                    // Floating action pill when card is focused
                    if isFocused {
                        HStack(spacing: 12) {
                            Button {
                                selectedCard = card
                            } label: {
                                Label("Card Details", systemImage: "info.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }

                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                                    focusedCardId = nil
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(9)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .offset(y: yOffset)
                .zIndex(isFocused ? 999 : Double(index))
                .animation(.spring(response: 0.42, dampingFraction: 0.76), value: focusedCardId)
            }
        }
        .frame(height: totalHeight)
        .padding(.horizontal, 18)
    }

    private func calculateCardOffset(index: Int, focusedIndex: Int?) -> CGFloat {
        let peekHeight: CGFloat = 68

        guard let focused = focusedIndex else {
            return CGFloat(index) * peekHeight
        }

        if index == focused {
            // Bring focused card to the top
            return CGFloat(focused) * 20
        } else if index < focused {
            // Push previous cards slightly up
            return CGFloat(index) * 24
        } else {
            // Push cards after the focused card down
            return CGFloat(focused) * 20 + 260 + CGFloat(index - focused) * 50
        }
    }

    private func handleCardTap(card: CardItem) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
            if focusedCardId == card.id {
                // If tapped twice while focused, open card details
                selectedCard = card
            } else {
                focusedCardId = card.id
            }
        }
    }

    // MARK: - Expanded List View

    private var expandedListView: some View {
        LazyVStack(spacing: 20) {
            ForEach(filteredCards) { card in
                CardRowView(card: card)
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        selectedCard = card
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .padding(.horizontal, 18)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 110, height: 110)

                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#818CF8")!, Color(hex: "#C084FC")!],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Your Vault is Empty")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Add credit cards, IDs, passports, loyalty passes, or membership cards.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showAddSheet = true
            } label: {
                Label("Add First Card", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#4F46E5")!, Color(hex: "#7C3AED")!],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: Color(hex: "#4F46E5")!.opacity(0.4), radius: 10, y: 5)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Category Filter Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chipButton(name: "All", isSelected: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                        focusedCardId = nil
                    }
                }

                ForEach(categories) { category in
                    chipButton(
                        name: category.name,
                        color: category.color,
                        isSelected: selectedCategory?.id == category.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = (selectedCategory?.id == category.id) ? nil : category
                            focusedCardId = nil
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private func chipButton(name: String, color: Color = .white, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    isSelected ? AnyShapeStyle(color.opacity(0.35)) : AnyShapeStyle(.white.opacity(0.08)),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color.opacity(0.65) : .white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Add Card Flow Router

/// Sheet presenting the add-card options (Camera scan or Manual entry).
struct AddCardFlowView: View {
    var onCardAdded: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera: Bool = false
    @State private var showManualEntry: Bool = false
    @State private var capturedFrontImage: UIImage?
    @State private var capturedBackImage: UIImage?
    @State private var showOCRReview: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.11)
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 96, height: 96)

                        Image(systemName: "plus.rectangle.on.rectangle.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#818CF8")!, Color(hex: "#C084FC")!],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 6) {
                        Text("Add to Vault")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Choose how you'd like to input your card details")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    VStack(spacing: 16) {
                        addOptionButton(
                            icon: "camera.fill",
                            title: "Scan with Camera",
                            subtitle: "Auto-crop and extract details using on-device OCR",
                            gradient: [Color(hex: "#2563EB")!, Color(hex: "#4F46E5")!]
                        ) {
                            showCamera = true
                        }

                        addOptionButton(
                            icon: "square.and.pencil",
                            title: "Enter Manually",
                            subtitle: "Choose card type and type in information",
                            gradient: [Color(hex: "#059669")!, Color(hex: "#0D9488")!]
                        ) {
                            showManualEntry = true
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView { front, back in
                    capturedFrontImage = front
                    capturedBackImage = back
                    showCamera = false
                    showOCRReview = true
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntryView(onSave: {
                    showManualEntry = false
                    onCardAdded?()
                    dismiss()
                })
            }
            .sheet(isPresented: $showOCRReview) {
                if let frontImage = capturedFrontImage {
                    OCRReviewView(
                        frontImage: frontImage,
                        backImage: capturedBackImage,
                        onSave: {
                            showOCRReview = false
                            onCardAdded?()
                            dismiss()
                        }
                    )
                }
            }
        }
    }

    private func addOptionButton(icon: String, title: String, subtitle: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 14)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}
