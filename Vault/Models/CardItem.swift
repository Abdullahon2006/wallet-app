import Foundation
import SwiftData
import SwiftUI

/// A single card or document stored in the vault.
@Model
final class CardItem {
    // MARK: - Identity
    var id: UUID
    var typeRawValue: String
    var displayName: String

    // MARK: - Images (JPEG compressed Data blobs)
    @Attribute(.externalStorage) var frontImageData: Data?
    @Attribute(.externalStorage) var backImageData: Data?

    // MARK: - Card metadata
    var cardNumber: String?
    var expiryDate: String?
    var cardholderName: String?
    var secondaryField: String?
    var notes: String?

    // MARK: - Barcode
    var barcodeData: String?
    var barcodeFormatRawValue: String?

    // MARK: - Appearance
    var colorHex: String
    var iconName: String

    // MARK: - Organisation
    var category: Category?

    // MARK: - Timestamps
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed helpers

    var cardType: CardType {
        get { CardType(rawValue: typeRawValue) ?? .custom }
        set { typeRawValue = newValue.rawValue }
    }

    var barcodeFormat: BarcodeFormat? {
        get {
            guard let raw = barcodeFormatRawValue else { return nil }
            return BarcodeFormat(rawValue: raw)
        }
        set { barcodeFormatRawValue = newValue?.rawValue }
    }

    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    /// Returns a masked card number for display (e.g., •••• 4242).
    var maskedNumber: String? {
        guard let number = cardNumber, number.count >= 4 else { return cardNumber }
        let last4 = String(number.suffix(4))
        return "•••• \(last4)"
    }

    // MARK: - Init

    init(
        type: CardType = .custom,
        displayName: String = "",
        frontImageData: Data? = nil,
        backImageData: Data? = nil,
        cardNumber: String? = nil,
        expiryDate: String? = nil,
        cardholderName: String? = nil,
        secondaryField: String? = nil,
        notes: String? = nil,
        barcodeData: String? = nil,
        barcodeFormat: BarcodeFormat? = nil,
        colorHex: String? = nil,
        iconName: String? = nil,
        category: Category? = nil
    ) {
        self.id = UUID()
        self.typeRawValue = type.rawValue
        self.displayName = displayName
        self.frontImageData = frontImageData
        self.backImageData = backImageData
        self.cardNumber = cardNumber
        self.expiryDate = expiryDate
        self.cardholderName = cardholderName
        self.secondaryField = secondaryField
        self.notes = notes
        self.barcodeData = barcodeData
        self.barcodeFormatRawValue = barcodeFormat?.rawValue
        self.colorHex = colorHex ?? type.defaultColor.toHex()
        self.iconName = iconName ?? type.iconName
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
