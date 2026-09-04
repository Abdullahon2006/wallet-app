import Foundation
import SwiftUI

/// Configuration for field labels, placeholders, and formatting rules tailored to each card type.
struct CardTypeConfig {
    let type: CardType
    let displayNameLabel: String
    let displayNamePlaceholder: String
    let numberLabel: String
    let numberPlaceholder: String
    let numberKeyboard: UIKeyboardType
    let holderLabel: String
    let holderPlaceholder: String
    let expiryLabel: String
    let expiryPlaceholder: String
    let secondaryLabel: String
    let secondaryPlaceholder: String
    let secondaryKeyboard: UIKeyboardType
    let defaultPalette: [Color]
    let badgeText: String

    static func config(for type: CardType) -> CardTypeConfig {
        switch type {
        case .creditDebit:
            return CardTypeConfig(
                type: type,
                displayNameLabel: "Bank / Card Name",
                displayNamePlaceholder: "e.g. Chase Sapphire, Apple Card",
                numberLabel: "Card Number",
                numberPlaceholder: "4532 •••• •••• 8892",
                numberKeyboard: .numberPad,
                holderLabel: "Cardholder Name",
                holderPlaceholder: "e.g. ALEX MORGAN",
                expiryLabel: "Valid Thru",
                expiryPlaceholder: "MM/YY",
                secondaryLabel: "CVV / CVC",
                secondaryPlaceholder: "123",
                secondaryKeyboard: .numberPad,
                defaultPalette: [Color(hex: "#1E1B4B")!, Color(hex: "#312E81")!, Color(hex: "#4338CA")!],
                badgeText: "DEBIT / CREDIT"
            )

        case .id:
            return CardTypeConfig(
                type: type,
                displayNameLabel: "Document Title",
                displayNamePlaceholder: "e.g. Driver's License, National ID",
                numberLabel: "License / ID Number",
                numberPlaceholder: "e.g. DL-9831048",
                numberKeyboard: .default,
                holderLabel: "Full Legal Name",
                holderPlaceholder: "e.g. JOHNATHAN DOE",
                expiryLabel: "Expiration Date",
                expiryPlaceholder: "e.g. 10/2030",
                secondaryLabel: "Date of Birth",
                secondaryPlaceholder: "e.g. 15/04/1992",
                secondaryKeyboard: .numbersAndPunctuation,
                defaultPalette: [Color(hex: "#0F2942")!, Color(hex: "#164E63")!, Color(hex: "#0891B2")!],
                badgeText: "IDENTIFICATION"
            )

        case .passport:
            return CardTypeConfig(
                type: type,
                displayNameLabel: "Issuing Country / Authority",
                displayNamePlaceholder: "e.g. United States of America",
                numberLabel: "Passport Number",
                numberPlaceholder: "e.g. A92817402",
                numberKeyboard: .asciiCapable,
                holderLabel: "Full Name (as in passport)",
                holderPlaceholder: "e.g. DOE, JOHNATHAN",
                expiryLabel: "Date of Expiration",
                expiryPlaceholder: "e.g. 24/11/2034",
                secondaryLabel: "Nationality / Code",
                secondaryPlaceholder: "e.g. USA / GBR / UZB",
                secondaryKeyboard: .default,
                defaultPalette: [Color(hex: "#31101E")!, Color(hex: "#4C0519")!, Color(hex: "#881337")!],
                badgeText: "PASSPORT"
            )

        case .loyalty:
            return CardTypeConfig(
                type: type,
                displayNameLabel: "Store / Program Name",
                displayNamePlaceholder: "e.g. Starbucks Rewards, Sephora",
                numberLabel: "Member / Account Number",
                numberPlaceholder: "e.g. 98402 19283",
                numberKeyboard: .numberPad,
                holderLabel: "Member Name",
                holderPlaceholder: "e.g. Alex Morgan",
                expiryLabel: "Valid Thru",
                expiryPlaceholder: "MM/YY or None",
                secondaryLabel: "Tier / Status",
                secondaryPlaceholder: "e.g. Gold Tier / 1,250 pts",
                secondaryKeyboard: .default,
                defaultPalette: [Color(hex: "#14532D")!, Color(hex: "#15803D")!, Color(hex: "#22C55E")!],
                badgeText: "REWARDS & LOYALTY"
            )

        case .membership:
            return CardTypeConfig(
                type: type,
                displayNameLabel: "Club / Organization",
                displayNamePlaceholder: "e.g. Costco Wholesale, Equinox",
                numberLabel: "Member ID #",
                numberPlaceholder: "e.g. MEM-409182",
                numberKeyboard: .default,
                holderLabel: "Member Name",
                holderPlaceholder: "e.g. Alex Morgan",
                expiryLabel: "Valid Thru",
                expiryPlaceholder: "e.g. 12/2026",
                secondaryLabel: "Membership Tier",
                secondaryPlaceholder: "e.g. Executive Member",
                secondaryKeyboard: .default,
                defaultPalette: [Color(hex: "#4A044E")!, Color(hex: "#701A75")!, Color(hex: "#A21CAF")!],
                badgeText: "MEMBERSHIP"
            )

        case .giftCard:
            return CardTypeConfig(
                type: type,
                displayNameLabel: "Merchant / Brand",
                displayNamePlaceholder: "e.g. Apple Gift Card, Amazon",
                numberLabel: "Gift Card Code",
                numberPlaceholder: "e.g. X92B-4819-2041",
                numberKeyboard: .default,
                holderLabel: "Recipient / Note",
                holderPlaceholder: "e.g. Birthday Gift from Sarah",
                expiryLabel: "Expiration",
                expiryPlaceholder: "e.g. No Expiration",
                secondaryLabel: "PIN / Security Code",
                secondaryPlaceholder: "e.g. 4819",
                secondaryKeyboard: .numberPad,
                defaultPalette: [Color(hex: "#7C2D12")!, Color(hex: "#C2410C")!, Color(hex: "#EA580C")!],
                badgeText: "GIFT CARD"
            )

        case .custom:
            return CardTypeConfig(
                type: type,
                displayNameLabel: "Card / Pass Title",
                displayNamePlaceholder: "e.g. Metro Transit, Keycard",
                numberLabel: "Serial / Identifier",
                numberPlaceholder: "e.g. 0192 8472 9102",
                numberKeyboard: .default,
                holderLabel: "Owner / Holder",
                holderPlaceholder: "e.g. Alex Morgan",
                expiryLabel: "Valid Until",
                expiryPlaceholder: "e.g. MM/YY or Ongoing",
                secondaryLabel: "Pass Type / Balance",
                secondaryPlaceholder: "e.g. Monthly Unlimited or $25.00",
                secondaryKeyboard: .default,
                defaultPalette: [Color(hex: "#18181B")!, Color(hex: "#27272A")!, Color(hex: "#3F3F46")!],
                badgeText: "TRANSIT & PASS"
            )
        }
    }

    /// Formats card number input based on card type.
    static func formatNumber(_ raw: String, for type: CardType) -> String {
        switch type {
        case .creditDebit:
            // Group 16 digits into chunks of 4: XXXX XXXX XXXX XXXX
            let digits = raw.filter { $0.isNumber }
            var result = ""
            for (index, char) in digits.prefix(19).enumerated() {
                if index > 0 && index % 4 == 0 {
                    result.append(" ")
                }
                result.append(char)
            }
            return result
        default:
            return raw
        }
    }
}
