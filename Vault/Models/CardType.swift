import Foundation
import SwiftUI

/// All supported card types in Vault.
enum CardType: String, Codable, CaseIterable, Identifiable {
    case creditDebit = "credit_debit"
    case loyalty     = "loyalty"
    case id          = "id"
    case passport    = "passport"
    case membership  = "membership"
    case giftCard    = "gift_card"
    case custom      = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .creditDebit: return "Credit / Debit"
        case .loyalty:     return "Loyalty"
        case .id:          return "ID"
        case .passport:    return "Passport"
        case .membership:  return "Membership"
        case .giftCard:    return "Gift Card"
        case .custom:      return "Custom"
        }
    }

    var iconName: String {
        switch self {
        case .creditDebit: return "creditcard.fill"
        case .loyalty:     return "star.fill"
        case .id:          return "person.text.rectangle.fill"
        case .passport:    return "book.closed.fill"
        case .membership:  return "person.crop.rectangle.fill"
        case .giftCard:    return "gift.fill"
        case .custom:      return "rectangle.fill"
        }
    }

    var defaultColor: Color {
        switch self {
        case .creditDebit: return Color(hue: 0.6, saturation: 0.7, brightness: 0.9)
        case .loyalty:     return Color(hue: 0.08, saturation: 0.8, brightness: 0.95)
        case .id:          return Color(hue: 0.55, saturation: 0.6, brightness: 0.85)
        case .passport:    return Color(hue: 0.95, saturation: 0.7, brightness: 0.85)
        case .membership:  return Color(hue: 0.3, saturation: 0.6, brightness: 0.8)
        case .giftCard:    return Color(hue: 0.8, saturation: 0.6, brightness: 0.9)
        case .custom:      return Color(hue: 0.0, saturation: 0.0, brightness: 0.5)
        }
    }
}

/// Supported barcode formats for loyalty/membership cards.
enum BarcodeFormat: String, Codable, CaseIterable, Identifiable {
    case qr       = "qr"
    case code128   = "code128"
    case pdf417    = "pdf417"
    case aztec     = "aztec"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .qr:      return "QR Code"
        case .code128: return "Code 128"
        case .pdf417:  return "PDF417"
        case .aztec:   return "Aztec"
        }
    }
}
