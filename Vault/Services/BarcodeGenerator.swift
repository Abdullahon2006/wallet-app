import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Generates barcode and QR code images using CoreImage filters.
enum BarcodeGenerator {

    /// Generates a barcode/QR image from the given data string and format.
    /// - Parameters:
    ///   - data: The string to encode.
    ///   - format: The barcode format to generate.
    ///   - size: The desired output size in points.
    /// - Returns: A rendered `UIImage`, or `nil` if generation failed.
    static func generate(from data: String, format: BarcodeFormat, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let ciImage = generateCIImage(from: data, format: format) else { return nil }

        // Scale up the CI image to the desired size
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let scale = min(scaleX, scaleY)

        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Generates a high-contrast barcode suitable for scanning (white on black background).
    static func generateForScanning(from data: String, format: BarcodeFormat, size: CGSize = CGSize(width: 600, height: 600)) -> UIImage? {
        generate(from: data, format: format, size: size)
    }

    // MARK: - CoreImage filter generation

    private static func generateCIImage(from data: String, format: BarcodeFormat) -> CIImage? {
        guard let messageData = data.data(using: .utf8) else { return nil }

        switch format {
        case .qr:
            let filter = CIFilter.qrCodeGenerator()
            filter.message = messageData
            filter.correctionLevel = "M"
            return filter.outputImage

        case .code128:
            let filter = CIFilter.code128BarcodeGenerator()
            filter.message = messageData
            filter.quietSpace = 7
            return filter.outputImage

        case .pdf417:
            let filter = CIFilter.pdf417BarcodeGenerator()
            filter.message = messageData
            return filter.outputImage

        case .aztec:
            let filter = CIFilter.aztecCodeGenerator()
            filter.message = messageData
            filter.correctionLevel = 23
            return filter.outputImage
        }
    }
}
