import SwiftUI

extension Color {
    /// Creates a `Color` from a hex string (e.g. "#FF5733" or "FF5733").
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        switch length {
        case 6:
            self.init(
                red: Double((rgb >> 16) & 0xFF) / 255.0,
                green: Double((rgb >> 8) & 0xFF) / 255.0,
                blue: Double(rgb & 0xFF) / 255.0
            )
        case 8:
            self.init(
                red: Double((rgb >> 24) & 0xFF) / 255.0,
                green: Double((rgb >> 16) & 0xFF) / 255.0,
                blue: Double((rgb >> 8) & 0xFF) / 255.0,
                opacity: Double(rgb & 0xFF) / 255.0
            )
        default:
            return nil
        }
    }

    /// Returns the hex string representation of this color (e.g. "#3A7BD5").
    func toHex() -> String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0

        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}
