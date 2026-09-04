import Foundation
import SwiftData
import SwiftUI

/// A user-defined folder / tag for organising cards.
@Model
final class Category {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String

    @Relationship(deleteRule: .nullify, inverse: \CardItem.category)
    var cards: [CardItem]

    var createdAt: Date

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    init(
        name: String,
        colorHex: String = "#4A90D9",
        iconName: String = "folder.fill"
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.cards = []
        self.createdAt = Date()
    }
}
