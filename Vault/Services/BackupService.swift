import Foundation
import SwiftData
import Compression
import UniformTypeIdentifiers

/// Handles encrypted export and import of the entire vault.
///
/// Export pipeline:  SwiftData → Codable structs → JSON → compressed → AES-256-GCM encrypted → .vaultbackup file
/// Import pipeline:  .vaultbackup file → decrypt → decompress → JSON → Codable structs → SwiftData
final class BackupService: @unchecked Sendable {
    static let shared = BackupService()
    private init() {}

    /// The custom UTType for vault backup files.
    static let backupUTType = UTType(exportedAs: "com.vault.backup", conformingTo: .data)

    // MARK: - Codable transfer objects

    struct BackupPayload: Codable {
        let version: Int
        let exportedAt: Date
        let categories: [CategoryDTO]
        let cards: [CardItemDTO]
    }

    struct CategoryDTO: Codable {
        let id: UUID
        let name: String
        let colorHex: String
        let iconName: String
        let createdAt: Date
    }

    struct CardItemDTO: Codable {
        let id: UUID
        let typeRawValue: String
        let displayName: String
        let frontImageData: Data?
        let backImageData: Data?
        let cardNumber: String?
        let expiryDate: String?
        let cardholderName: String?
        let notes: String?
        let barcodeData: String?
        let barcodeFormatRawValue: String?
        let colorHex: String
        let iconName: String
        let categoryId: UUID?
        let createdAt: Date
        let updatedAt: Date
    }

    // MARK: - Export

    /// Exports all data from the model context as an encrypted `.vaultbackup` file.
    /// - Parameters:
    ///   - modelContext: The SwiftData model context to read from.
    ///   - passphrase: The passphrase to encrypt the backup with.
    /// - Returns: The encrypted backup data.
    func exportBackup(modelContext: ModelContext, passphrase: String) throws -> Data {
        // Fetch all data
        let categories = try modelContext.fetch(FetchDescriptor<Category>())
        let cards = try modelContext.fetch(FetchDescriptor<CardItem>())

        // Convert to DTOs
        let categoryDTOs = categories.map { cat in
            CategoryDTO(
                id: cat.id,
                name: cat.name,
                colorHex: cat.colorHex,
                iconName: cat.iconName,
                createdAt: cat.createdAt
            )
        }

        let cardDTOs = cards.map { card in
            CardItemDTO(
                id: card.id,
                typeRawValue: card.typeRawValue,
                displayName: card.displayName,
                frontImageData: card.frontImageData,
                backImageData: card.backImageData,
                cardNumber: card.cardNumber,
                expiryDate: card.expiryDate,
                cardholderName: card.cardholderName,
                notes: card.notes,
                barcodeData: card.barcodeData,
                barcodeFormatRawValue: card.barcodeFormatRawValue,
                colorHex: card.colorHex,
                iconName: card.iconName,
                categoryId: card.category?.id,
                createdAt: card.createdAt,
                updatedAt: card.updatedAt
            )
        }

        let payload = BackupPayload(
            version: 1,
            exportedAt: Date(),
            categories: categoryDTOs,
            cards: cardDTOs
        )

        // Serialize → compress → encrypt
        let jsonData = try JSONEncoder().encode(payload)
        let compressed = try compress(jsonData)
        let encrypted = try CryptoManager.encrypt(compressed, passphrase: passphrase)

        return encrypted
    }

    // MARK: - Import

    /// Imports a `.vaultbackup` file into the given model context.
    /// - Parameters:
    ///   - data: The encrypted backup data.
    ///   - passphrase: The passphrase used during export.
    ///   - modelContext: The SwiftData model context to insert into.
    /// - Returns: A summary of what was imported.
    @discardableResult
    func importBackup(data: Data, passphrase: String, modelContext: ModelContext) throws -> ImportSummary {
        // Decrypt → decompress → deserialize
        let decrypted = try CryptoManager.decrypt(data, passphrase: passphrase)
        let decompressed = try decompress(decrypted)
        let payload = try JSONDecoder().decode(BackupPayload.self, from: decompressed)

        // Insert categories first (cards reference them)
        var categoryMap: [UUID: Category] = [:]
        for dto in payload.categories {
            let category = Category(name: dto.name, colorHex: dto.colorHex, iconName: dto.iconName)
            category.id = dto.id
            category.createdAt = dto.createdAt
            modelContext.insert(category)
            categoryMap[dto.id] = category
        }

        // Insert cards
        for dto in payload.cards {
            let card = CardItem(
                type: CardType(rawValue: dto.typeRawValue) ?? .custom,
                displayName: dto.displayName,
                frontImageData: dto.frontImageData,
                backImageData: dto.backImageData,
                cardNumber: dto.cardNumber,
                expiryDate: dto.expiryDate,
                cardholderName: dto.cardholderName,
                notes: dto.notes,
                barcodeData: dto.barcodeData,
                barcodeFormat: dto.barcodeFormatRawValue.flatMap { BarcodeFormat(rawValue: $0) },
                colorHex: dto.colorHex,
                iconName: dto.iconName,
                category: dto.categoryId.flatMap { categoryMap[$0] }
            )
            card.id = dto.id
            card.createdAt = dto.createdAt
            card.updatedAt = dto.updatedAt
            modelContext.insert(card)
        }

        try modelContext.save()

        return ImportSummary(
            categoriesImported: payload.categories.count,
            cardsImported: payload.cards.count,
            exportedAt: payload.exportedAt
        )
    }

    struct ImportSummary {
        let categoriesImported: Int
        let cardsImported: Int
        let exportedAt: Date
    }

    // MARK: - Compression (using Apple's Compression framework)

    private func compress(_ data: Data) throws -> Data {
        let bufferSize = max(data.count, 64)
        var destinationBuffer = Data(count: bufferSize)

        let compressedSize = destinationBuffer.withUnsafeMutableBytes { destPtr in
            data.withUnsafeBytes { srcPtr in
                compression_encode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    bufferSize,
                    srcPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    data.count,
                    nil,
                    COMPRESSION_LZFSE
                )
            }
        }

        guard compressedSize > 0 else {
            throw BackupError.compressionFailed
        }

        // Prepend original size (8 bytes) for decompression
        var originalSize = UInt64(data.count)
        let sizeData = Data(bytes: &originalSize, count: 8)
        return sizeData + destinationBuffer.prefix(compressedSize)
    }

    private func decompress(_ data: Data) throws -> Data {
        guard data.count > 8 else {
            throw BackupError.invalidBackupFile
        }

        let sizeData = data.prefix(8)
        let compressedData = data.dropFirst(8)

        let originalSize = sizeData.withUnsafeBytes { $0.load(as: UInt64.self) }
        let bufferSize = Int(originalSize)

        var destinationBuffer = Data(count: bufferSize)

        let decompressedSize = destinationBuffer.withUnsafeMutableBytes { destPtr in
            compressedData.withUnsafeBytes { srcPtr in
                compression_decode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    bufferSize,
                    srcPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    compressedData.count,
                    nil,
                    COMPRESSION_LZFSE
                )
            }
        }

        guard decompressedSize > 0 else {
            throw BackupError.decompressionFailed
        }

        return destinationBuffer.prefix(decompressedSize)
    }

    // MARK: - Errors

    enum BackupError: LocalizedError {
        case compressionFailed
        case decompressionFailed
        case invalidBackupFile

        var errorDescription: String? {
            switch self {
            case .compressionFailed:    return "Failed to compress backup data."
            case .decompressionFailed:  return "Failed to decompress backup data."
            case .invalidBackupFile:    return "The file is not a valid Vault backup."
            }
        }
    }
}

// MARK: - UTType extension for .vaultbackup files

extension UTType {
    static var vaultBackup: UTType {
        UTType(exportedAs: "com.vault.backup", conformingTo: .data)
    }
}
