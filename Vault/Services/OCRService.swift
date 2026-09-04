import Foundation
import Vision
import UIKit

/// On-device OCR using Apple's Vision framework. No network calls.
enum OCRService {

    /// Structured result from OCR processing.
    struct OCRResult {
        var cardNumber: String?
        var expiryDate: String?
        var cardholderName: String?
        var allText: String
        var confidence: Float
    }

    /// Runs OCR on the given image and returns extracted card fields.
    static func recognizeText(in image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        let recognizedStrings = try await performRecognition(on: cgImage)
        let allText = recognizedStrings.map(\.string).joined(separator: "\n")
        let avgConfidence = recognizedStrings.isEmpty ? 0 :
            recognizedStrings.map(\.confidence).reduce(0, +) / Float(recognizedStrings.count)

        return OCRResult(
            cardNumber: extractCardNumber(from: recognizedStrings),
            expiryDate: extractExpiryDate(from: recognizedStrings),
            cardholderName: extractName(from: recognizedStrings),
            allText: allText,
            confidence: avgConfidence
        )
    }

    // MARK: - Vision recognition

    private static func performRecognition(on cgImage: CGImage) async throws -> [(string: String, confidence: Float)] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let results = observations.compactMap { observation -> (string: String, confidence: Float)? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return (candidate.string, candidate.confidence)
                }
                continuation.resume(returning: results)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Field extraction

    /// Extracts a potential card number (13-19 digit sequence, optionally with spaces/dashes).
    private static func extractCardNumber(from results: [(string: String, confidence: Float)]) -> String? {
        // Match groups of digits that look like card numbers
        let pattern = #"(?:\d[\s\-]*){13,19}"#
        for result in results {
            if let match = result.string.range(of: pattern, options: .regularExpression) {
                let raw = String(result.string[match])
                let digitsOnly = raw.filter(\.isNumber)
                if digitsOnly.count >= 13 && digitsOnly.count <= 19 && luhnCheck(digitsOnly) {
                    return digitsOnly
                }
            }
        }
        // Fallback: find any long digit sequence
        for result in results {
            let digitsOnly = result.string.filter(\.isNumber)
            if digitsOnly.count >= 13 && digitsOnly.count <= 19 {
                return digitsOnly
            }
        }
        return nil
    }

    /// Extracts an expiry date in MM/YY or MM/YYYY format.
    private static func extractExpiryDate(from results: [(string: String, confidence: Float)]) -> String? {
        let pattern = #"\b(0[1-9]|1[0-2])\s*[/\-]\s*(\d{2,4})\b"#
        for result in results {
            if let match = result.string.range(of: pattern, options: .regularExpression) {
                return String(result.string[match])
                    .replacingOccurrences(of: " ", with: "")
            }
        }
        return nil
    }

    /// Attempts to extract a cardholder name (uppercase letters, likely a name).
    private static func extractName(from results: [(string: String, confidence: Float)]) -> String? {
        let pattern = #"^[A-Z][A-Z\s\.\-]{2,}[A-Z]$"#
        for result in results {
            let trimmed = result.string.trimmingCharacters(in: .whitespaces)
            if trimmed.range(of: pattern, options: .regularExpression) != nil {
                // Skip common non-name labels
                let skipWords = ["VISA", "MASTERCARD", "AMERICAN EXPRESS", "DISCOVER",
                                 "VALID", "THRU", "GOOD", "EXPIRES", "DEBIT", "CREDIT",
                                 "PLATINUM", "GOLD", "SIGNATURE"]
                if !skipWords.contains(where: { trimmed.contains($0) }) {
                    return trimmed
                }
            }
        }
        return nil
    }

    /// Luhn algorithm for card number validation.
    private static func luhnCheck(_ number: String) -> Bool {
        let digits = number.compactMap { Int(String($0)) }
        guard digits.count >= 13 else { return false }

        var sum = 0
        for (index, digit) in digits.reversed().enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }

    // MARK: - Errors

    enum OCRError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "Could not process the image for text recognition."
            }
        }
    }
}
