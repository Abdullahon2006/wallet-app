import SwiftUI

/// Full-screen barcode/QR display optimized for in-store scanning.
/// Automatically maximizes screen brightness on appear.
struct BarcodeDisplayView: View {
    let data: String
    let format: BarcodeFormat
    let cardName: String

    @Environment(\.dismiss) private var dismiss
    @State private var previousBrightness: CGFloat = 0.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Card name
                Text(cardName)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))

                // Barcode image
                if let barcodeImage = BarcodeGenerator.generateForScanning(
                    from: data,
                    format: format,
                    size: barcodeSize
                ) {
                    Image(uiImage: barcodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .frame(maxWidth: 320, maxHeight: 320)
                } else {
                    ContentUnavailableView(
                        "Could not generate barcode",
                        systemImage: "exclamationmark.triangle",
                        description: Text("The barcode data may be invalid for this format.")
                    )
                    .foregroundStyle(.white)
                }

                // Format label
                Text(format.displayName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))

                // Data (truncated)
                Text(data)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding(.horizontal, 40)

                Spacer()

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(.white, in: Capsule())
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Save current brightness and maximize for scanning
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        }
        .onDisappear {
            // Restore previous brightness
            UIScreen.main.brightness = previousBrightness
        }
        .statusBarHidden(true)
    }

    private var barcodeSize: CGSize {
        switch format {
        case .qr, .aztec:
            return CGSize(width: 600, height: 600)
        case .code128:
            return CGSize(width: 600, height: 200)
        case .pdf417:
            return CGSize(width: 600, height: 300)
        }
    }
}
