import SwiftUI

/// A text view that blurs its content when sensitive mode is enabled.
/// Tapping reveals the text temporarily.
struct SensitiveText: View {
    let text: String
    var font: Font = .body
    var foregroundStyle: AnyShapeStyle = AnyShapeStyle(.primary)

    @State private var isRevealed: Bool = false
    @State private var lockManager = LockManager.shared

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(foregroundStyle)
            .blur(radius: shouldBlur ? 8 : 0)
            .animation(.easeInOut(duration: 0.2), value: shouldBlur)
            .onTapGesture {
                if lockManager.isSensitiveModeEnabled {
                    withAnimation {
                        isRevealed = true
                    }
                    // Auto-hide after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            isRevealed = false
                        }
                    }
                }
            }
    }

    private var shouldBlur: Bool {
        lockManager.isSensitiveModeEnabled && !isRevealed
    }
}
