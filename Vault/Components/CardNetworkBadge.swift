import SwiftUI

/// Identifies card networks based on prefix digits and renders authentic vector badges.
enum CardNetwork: String {
    case visa
    case mastercard
    case amex
    case discover
    case generic

    static func detect(from number: String?) -> CardNetwork {
        guard let num = number?.filter({ $0.isNumber }), !num.isEmpty else {
            return .generic
        }
        if num.hasPrefix("4") {
            return .visa
        } else if num.hasPrefix("51") || num.hasPrefix("52") || num.hasPrefix("53") || num.hasPrefix("54") || num.hasPrefix("55") || (num.hasPrefix("2") && num.count >= 2) {
            return .mastercard
        } else if num.hasPrefix("34") || num.hasPrefix("37") {
            return .amex
        } else if num.hasPrefix("6011") || num.hasPrefix("65") {
            return .discover
        }
        return .generic
    }
}

struct CardNetworkBadge: View {
    let network: CardNetwork

    var body: some View {
        switch network {
        case .visa:
            Text("VISA")
                .font(.system(size: 17, weight: .black, design: .serif))
                .italic()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: "#F59E0B")!],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .tracking(1.5)

        case .mastercard:
            HStack(spacing: -10) {
                Circle()
                    .fill(Color(hex: "#EF4444")!)
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(Color(hex: "#F59E0B")!.opacity(0.9))
                    .frame(width: 22, height: 22)
            }
            .shadow(color: .black.opacity(0.3), radius: 2)

        case .amex:
            Text("AMEX")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(hex: "#0284C7")!, in: RoundedRectangle(cornerRadius: 4))

        case .discover:
            HStack(spacing: 2) {
                Text("DISC")
                    .font(.system(size: 12, weight: .bold))
                Circle()
                    .fill(Color(hex: "#F97316")!)
                    .frame(width: 9, height: 9)
                Text("VER")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white)

        case .generic:
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.caption2)
                Text("VAULT")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
            }
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.12), in: Capsule())
        }
    }
}
