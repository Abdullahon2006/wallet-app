import SwiftUI

/// A single card rendered as a premium physical card in the wallet deck view.
struct CardRowView: View {
    let card: CardItem
    var isExpanded: Bool = false
    @State private var lockManager = LockManager.shared

    var body: some View {
        CardVisualView(
            type: card.cardType,
            displayName: card.displayName,
            cardNumber: card.cardNumber,
            cardholderName: card.cardholderName,
            expiryDate: card.expiryDate,
            secondaryField: card.secondaryField,
            colorHex: card.colorHex,
            frontImageData: card.frontImageData,
            barcodeData: card.barcodeData,
            barcodeFormat: card.barcodeFormat,
            categoryColor: card.category?.color,
            isSensitive: lockManager.isSensitiveModeEnabled
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
