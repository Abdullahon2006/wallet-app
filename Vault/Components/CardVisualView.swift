import SwiftUI

/// A photorealistic, high-fidelity card visualization supporting distinct layouts and materials
/// for every card type (Credit/Debit, ID, Loyalty, Passport, Membership, Transit, Gift Card).
struct CardVisualView: View {
    var type: CardType
    var displayName: String
    var cardNumber: String?
    var cardholderName: String?
    var expiryDate: String?
    var secondaryField: String?
    var colorHex: String
    var frontImageData: Data?
    var barcodeData: String?
    var barcodeFormat: BarcodeFormat?
    var categoryColor: Color?
    var isSensitive: Bool = false

    var baseColor: Color {
        Color(hex: colorHex) ?? type.defaultColor
    }

    var body: some View {
        ZStack {
            // Background Layer
            cardBackground

            // Specular / Glossy light reflection
            glossOverlay

            // Content layer tailored to card type
            VStack(spacing: 0) {
                switch type {
                case .creditDebit:
                    creditDebitFace
                case .id:
                    idCardFace
                case .passport:
                    passportFace
                case .loyalty:
                    loyaltyFace
                case .membership:
                    membershipFace
                case .giftCard:
                    giftCardFace
                case .custom:
                    customFace
                }
            }
            .padding(18)

            // Chamfered border stroke
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.45),
                            .white.opacity(0.15),
                            .clear,
                            .white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .aspectRatio(1.586, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: baseColor.opacity(0.35), radius: 14, x: 0, y: 8)
    }

    // MARK: - Backgrounds & Overlays

    @ViewBuilder
    private var cardBackground: some View {
        if let data = frontImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(1.586, contentMode: .fill)
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.2), .black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
            ZStack {
                // Multi-stop rich gradient
                LinearGradient(
                    colors: [
                        baseColor,
                        baseColor.opacity(0.82),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Background artwork / texture
                backgroundPattern
            }
        }
    }

    @ViewBuilder
    private var backgroundPattern: some View {
        switch type {
        case .creditDebit:
            // Curved metallic wave ripples
            GeometryReader { geo in
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 50)
                    .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                    .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.4)
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 30)
                    .frame(width: geo.size.width * 0.9, height: geo.size.width * 0.9)
                    .offset(x: -geo.size.width * 0.25, y: geo.size.height * 0.4)
            }

        case .id:
            // Guilloche micro security mesh
            VStack(spacing: 6) {
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.025))
                        .frame(height: 1)
                }
            }
            .rotationEffect(.degrees(-15))

        case .passport:
            // Leather / deep texture with gold corner flourishes
            ZStack {
                Color.black.opacity(0.15)
                Rectangle()
                    .stroke(Color(hex: "#F59E0B")!.opacity(0.2), lineWidth: 1)
                    .padding(8)
            }

        case .loyalty, .membership:
            // Bold geometric accent
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 260, height: 260)
                .offset(x: 130, y: -40)

        case .giftCard, .custom:
            // Diagonal beam
            LinearGradient(
                colors: [.white.opacity(0.08), .clear],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    private var glossOverlay: some View {
        LinearGradient(
            colors: [
                .white.opacity(0.18),
                .white.opacity(0.03),
                .clear,
                .white.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .allowsHitTesting(false)
    }

    // MARK: - 1. Credit / Debit Face

    private var creditDebitFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Bank / Card Name & Contactless + Category
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName.isEmpty ? "VAULT CARD" : displayName.uppercased())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(1.0)
                        .lineLimit(1)

                    Text("DEBIT / CREDIT")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                        .tracking(1.2)
                }

                Spacer()

                HStack(spacing: 8) {
                    if let catColor = categoryColor {
                        Circle()
                            .fill(catColor)
                            .frame(width: 8, height: 8)
                    }

                    Image(systemName: "wave.3.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }

            Spacer()

            // EMV Smart Chip
            EMVChipView(size: 34, isGold: true)
                .padding(.bottom, 6)

            // Card Number (embossed feel)
            Text(formattedCardNumber)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                .tracking(2.0)
                .lineLimit(1)

            Spacer()

            // Footer: Cardholder, Valid Thru, Network
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CARDHOLDER")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(1.0)

                    Text(cardholderName?.isEmpty == false ? cardholderName!.uppercased() : "NAME ON CARD")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(0.8)
                        .lineLimit(1)
                }

                Spacer()

                if let exp = expiryDate, !exp.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VALID THRU")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(0.8)

                        Text(exp)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.trailing, 10)
                }

                CardNetworkBadge(network: CardNetwork.detect(from: cardNumber))
            }
        }
    }

    // MARK: - 2. ID / Driver's License Face

    private var idCardFace: some View {
        VStack(alignment: .leading, spacing: 8) {
            // State / Authority Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.caption)
                    Text(displayName.isEmpty ? "DRIVER LICENSE" : displayName.uppercased())
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.0)
                }
                .foregroundStyle(.white)

                Spacer()

                Text("USA")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
            }
            .padding(.bottom, 2)

            Divider()
                .background(.white.opacity(0.2))

            // Body: Photo slot & Info Grid
            HStack(alignment: .top, spacing: 14) {
                // Photo slot / Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.12))
                        .frame(width: 58, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )

                    VStack(spacing: 4) {
                        Image(systemName: "person.crop.rectangle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white.opacity(0.65))
                        Text("PHOTO")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                // Field Details
                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("LIC NO.")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(cardNumber?.isEmpty == false ? cardNumber! : "DL-00000000")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("NAME")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(cardholderName?.isEmpty == false ? cardholderName!.uppercased() : "FIRSTNAME LASTNAME")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    HStack(spacing: 12) {
                        if let dob = secondaryField, !dob.isEmpty {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DOB")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(dob)
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }

                        if let exp = expiryDate, !exp.isEmpty {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("EXP")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(exp)
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#F87171")!)
                            }
                        }
                    }
                }

                Spacer()
            }

            Spacer()

            // Micro security barcode footer
            HStack {
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(i % 2 == 0 ? 0.35 : 0.15))
                            .frame(width: (i % 3 == 0 ? 3 : 1.5), height: 10)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 9))
                    Text("VERIFIED ID")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(Color(hex: "#38BDF8")!)
            }
        }
    }

    // MARK: - 3. Passport Face

    private var passportFace: some View {
        VStack(spacing: 6) {
            // Gold Seal Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PASSPORT")
                        .font(.system(size: 14, weight: .black, design: .serif))
                        .foregroundStyle(Color(hex: "#FDE047")!)
                        .tracking(3.0)

                    Text(displayName.isEmpty ? "UNITED STATES OF AMERICA" : displayName.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(1.0)
                }

                Spacer()

                Image(systemName: "globe.americas.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: "#FDE047")!.opacity(0.85))
            }

            Spacer()

            // Main info section
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cardholderName?.isEmpty == false ? cardholderName!.uppercased() : "DOE, JOHNATHAN")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("PASSPORT NO.")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color(hex: "#FDE047")!.opacity(0.6))
                            Text(cardNumber?.isEmpty == false ? cardNumber! : "A00000000")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                        }

                        if let exp = expiryDate, !exp.isEmpty {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("EXPIRY")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(Color(hex: "#FDE047")!.opacity(0.6))
                                Text(exp)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }

                        if let nat = secondaryField, !nat.isEmpty {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("NATIONALITY")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(Color(hex: "#FDE047")!.opacity(0.6))
                                Text(nat.uppercased())
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }

                Spacer()
            }

            Spacer()

            // Machine-readable zone (MRZ) chevrons
            HStack {
                Text("P<USA<<\(cardholderName?.replacingOccurrences(of: " ", with: "<").uppercased() ?? "DOE<<JOHN")<<<<<<<<<<<<<<<<")
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color(hex: "#FDE047")!.opacity(0.45))
                    .lineLimit(1)
                Spacer()
            }
        }
    }

    // MARK: - 4. Loyalty / Rewards Face

    private var loyaltyFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName.isEmpty ? "REWARDS CLUB" : displayName.uppercased())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text(secondaryField?.isEmpty == false ? secondaryField!.uppercased() : "MEMBER TIER")
                            .font(.system(size: 8, weight: .heavy))
                    }
                    .foregroundStyle(Color(hex: "#F59E0B")!)
                }

                Spacer()

                Image(systemName: "giftcard.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Text(cardholderName?.isEmpty == false ? cardholderName! : "Member")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text(cardNumber?.isEmpty == false ? cardNumber! : "98201 02819")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))

            Spacer()

            // Barcode preview
            HStack {
                HStack(spacing: 2) {
                    ForEach(0..<28, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(i % 3 == 0 ? 0.9 : 0.4))
                            .frame(width: (i % 4 == 0 ? 3 : (i % 2 == 0 ? 1.5 : 2)), height: 22)
                    }
                }
                .padding(4)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))

                Spacer()

                if let exp = expiryDate, !exp.isEmpty {
                    Text("EXP: \(exp)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - 5. Membership Face

    private var membershipFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName.isEmpty ? "MEMBERSHIP PASS" : displayName.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(secondaryField?.isEmpty == false ? secondaryField! : "ALL ACCESS")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(Color(hex: "#C084FC")!)
                }

                Spacer()

                Image(systemName: "person.crop.rectangle.badge.plus")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            Text(cardholderName?.isEmpty == false ? cardholderName! : "Member Name")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            Text(cardNumber?.isEmpty == false ? cardNumber! : "ID: MEM-00000")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))

            Spacer()

            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("ACTIVE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.green)
                }

                Spacer()

                if let exp = expiryDate, !exp.isEmpty {
                    Text("VALID: \(exp)")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - 6. Gift Card Face

    private var giftCardFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName.isEmpty ? "GIFT CARD" : displayName.uppercased())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("PREPAID VOUCHER")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: "#FDE047")!)
            }

            Spacer()

            Text(cardNumber?.isEmpty == false ? cardNumber! : "XXXX-XXXX-XXXX")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .tracking(1.5)

            Spacer()

            HStack {
                if let holder = cardholderName, !holder.isEmpty {
                    Text(holder)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer()

                if let pin = secondaryField, !pin.isEmpty {
                    Text("PIN: \(pin)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    // MARK: - 7. Custom / Transit Face

    private var customFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName.isEmpty ? "TRANSIT PASS" : displayName.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("TAP TO TOUCH IN / OUT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "tram.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            HStack {
                EMVChipView(size: 30, isGold: false)
                Spacer()
                if let sec = secondaryField, !sec.isEmpty {
                    Text(sec)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.15), in: Capsule())
                }
            }

            Spacer()

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(cardNumber?.isEmpty == false ? cardNumber! : "0000 0000 0000")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    if let holder = cardholderName, !holder.isEmpty {
                        Text(holder)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                Spacer()

                if let exp = expiryDate, !exp.isEmpty {
                    Text(exp)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Helper Formatting

    private var formattedCardNumber: String {
        guard let number = cardNumber, !number.isEmpty else {
            return "••••  ••••  ••••  ••••"
        }
        if isSensitive {
            let digits = number.filter { $0.isNumber }
            let last4 = digits.suffix(4)
            return "••••  ••••  ••••  \(last4)"
        }
        return CardTypeConfig.formatNumber(number, for: type)
    }
}
