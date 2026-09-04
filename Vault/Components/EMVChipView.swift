import SwiftUI

/// A photorealistic EMV Smart Chip and contactless symbol for digital payment cards.
struct EMVChipView: View {
    var size: CGFloat = 36
    var isGold: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            // Chip
            ZStack {
                // Base plate
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: isGold
                                ? [Color(hex: "#FDE047")!, Color(hex: "#D97706")!, Color(hex: "#F59E0B")!, Color(hex: "#B45309")!]
                                : [Color(hex: "#E2E8F0")!, Color(hex: "#94A3B8")!, Color(hex: "#CBD5E1")!, Color(hex: "#64748B")!],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.3), lineWidth: 0.7)
                    )

                // Circuit lines
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    Path { path in
                        // Center cross dividing line
                        path.move(to: CGPoint(x: w * 0.35, y: 0))
                        path.addLine(to: CGPoint(x: w * 0.35, y: h))

                        path.move(to: CGPoint(x: w * 0.65, y: 0))
                        path.addLine(to: CGPoint(x: w * 0.65, y: h))

                        path.move(to: CGPoint(x: 0, y: h * 0.5))
                        path.addLine(to: CGPoint(x: w, y: h * 0.5))

                        // Inner core box
                        path.addRoundedRect(
                            in: CGRect(x: w * 0.25, y: h * 0.25, width: w * 0.5, height: h * 0.5),
                            cornerSize: CGSize(width: 2, height: 2)
                        )
                    }
                    .stroke(Color.black.opacity(0.35), lineWidth: 0.8)
                }
            }
            .frame(width: size, height: size * 0.75)
            .shadow(color: .black.opacity(0.25), radius: 1, y: 1)

            // Contactless Wave Glyph
            Image(systemName: "wave.3.right")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

#Preview {
    ZStack {
        Color.black
        EMVChipView()
    }
}
