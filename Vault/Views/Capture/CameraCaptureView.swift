import SwiftUI
import VisionKit

/// Wraps `VNDocumentCameraViewController` for capturing card front/back images.
@MainActor
struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: @MainActor @Sendable (_ frontImage: UIImage, _ backImage: UIImage?) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate, @unchecked Sendable {
        let onCapture: @MainActor @Sendable (_ frontImage: UIImage, _ backImage: UIImage?) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping @MainActor @Sendable (_ frontImage: UIImage, _ backImage: UIImage?) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // First page = front, second page (if any) = back
            let frontImage = scan.imageOfPage(at: 0)
            let backImage = scan.pageCount > 1 ? scan.imageOfPage(at: 1) : nil

            Task { @MainActor in
                self.onCapture(frontImage, backImage)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            Task { @MainActor in
                self.dismiss()
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("[CameraCapture] Failed: \(error.localizedDescription)")
            Task { @MainActor in
                self.dismiss()
            }
        }
    }
}
