import SwiftUI

/// A color picker presenting a curated palette for card/category colors.
struct CardColorPicker: View {
    @Binding var selectedHex: String

    private let palette: [(name: String, hex: String)] = [
        ("Slate",    "#475569"),
        ("Rose",     "#E11D48"),
        ("Orange",   "#EA580C"),
        ("Amber",    "#D97706"),
        ("Emerald",  "#059669"),
        ("Teal",     "#0D9488"),
        ("Cyan",     "#0891B2"),
        ("Blue",     "#2563EB"),
        ("Indigo",   "#4F46E5"),
        ("Violet",   "#7C3AED"),
        ("Purple",   "#9333EA"),
        ("Fuchsia",  "#C026D3"),
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
            ForEach(palette, id: \.hex) { item in
                let color = Color(hex: item.hex) ?? .gray
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: selectedHex == item.hex ? 3 : 0)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .opacity(selectedHex == item.hex ? 1 : 0)
                    )
                    .scaleEffect(selectedHex == item.hex ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: selectedHex)
                    .onTapGesture {
                        selectedHex = item.hex
                    }
                    .accessibilityLabel(item.name)
            }
        }
    }
}
