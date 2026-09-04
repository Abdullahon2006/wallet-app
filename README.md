# Vault

A local-only digital card wallet for iOS. Store credit cards, loyalty cards, IDs, passports, memberships, and more — all encrypted, all on-device, with zero cloud dependency.

> **This is not a payment app.** Vault stores card *images and metadata* for your reference. It does not process payments or interact with any payment network.

## Features

- 📷 **Camera capture** with auto-crop (VisionKit) and on-device OCR (Vision framework)
- 🃏 **3D card view** — drag to rotate and flip between front and back (SceneKit)
- 🔐 **Biometric unlock** (Face ID / Touch ID) with 6-digit passcode fallback
- 🔒 **Encrypted at rest** — file protection + Keychain-held key
- 📊 **Barcode / QR display** at full brightness for in-store scanning
- 📁 **Category folders** with custom colors and icons
- 💾 **Encrypted backups** — export/import `.vaultbackup` files, AES-256-GCM encrypted
- 🛡️ **Sensitive mode** — blur card numbers in list view until tapped
- ✈️ **Works in airplane mode** — always. There is no network layer.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Building

```bash
# Clone the repo
git clone <repo-url> vault
cd vault

# Generate Xcode project (requires xcodegen: brew install xcodegen)
xcodegen generate

# Open in Xcode
open Vault.xcodeproj

# Or build from command line
xcodebuild build \
  -project Vault.xcodeproj \
  -scheme Vault \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Security Model

### What's encrypted

| Layer | Mechanism | Protects against |
|-------|-----------|-----------------|
| **Data at rest** | `NSFileProtectionComplete` on the SwiftData store file | Reading the database file when the device is locked |
| **Keychain** | 256-bit AES key stored with `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` | Key extraction on devices without a passcode, and on other devices |
| **Passcode** | Salted HKDF-SHA256 key derivation in Keychain — raw passcode is **never** stored | Passcode recovery from stored data |
| **Backup files** | AES-256-GCM with HKDF-derived key from user passphrase | Reading backup files without the passphrase |
| **App unlock** | Face ID / Touch ID via `LocalAuthentication`, falling back to app passcode | Unauthorized access to the app |

### What "local-only" actually means

- **No network permissions**: The app does not include `NSAppTransportSecurity`, does not import `URLSession`, and makes zero network calls. You can verify this by grepping the source.
- **No backend**: There is no server, no API, no account creation, no login. The app has no concept of a "user" beyond the device owner.
- **No analytics**: No crash reporting SDK, no telemetry, no tracking pixels, no third-party frameworks.
- **No sync**: Data lives on one device. There is no CloudKit container, no iCloud key-value store, no sync layer of any kind.
- **Backup is manual**: The export/import flow writes a file to a location the user chooses (Files app, AirDrop, USB drive). The app does not initiate the transfer.

### What this does NOT protect against

- **Jailbroken devices**: On a jailbroken device, all bets are off. File protection and Keychain protections can be bypassed.
- **Physical access with device passcode**: If an attacker has your device *and* your device passcode, they can unlock the device, reset Face ID, and access the Keychain.
- **Memory dumps**: While the app is running and unlocked, card data is in memory.
- **Screenshots / screen recording**: iOS allows screenshots and screen recording. Vault does not currently block these.
- **Compromised backups**: If you export a backup and store it somewhere insecure, and your passphrase is weak, the backup could be brute-forced.

### Recommendations

1. Use a strong device passcode (not 4 digits)
2. Keep iOS up to date
3. Use a strong, unique passphrase for backups
4. Don't store backups in plaintext cloud storage without additional encryption
5. Enable "Sensitive Mode" in Settings to blur card numbers in daily use

## Architecture

```
Vault/
├── Models/          # SwiftData @Model classes (CardItem, Category)
├── Security/        # Keychain, biometrics, lock state, crypto
├── Services/        # OCR, barcode generation, backup
├── Views/           # SwiftUI views organized by feature
│   ├── Lock/        # Lock screen, passcode setup
│   ├── Cards/       # Deck view, card row, 3D detail
│   ├── Capture/     # Camera, OCR review, manual entry
│   ├── Categories/  # Category list and editor
│   ├── Barcode/     # Full-screen barcode display
│   ├── Backup/      # Export and import flows
│   └── Settings/    # App settings
├── Components/      # Reusable UI components
└── Extensions/      # Swift extensions
```

## License

MIT — see [LICENSE](LICENSE).

## Contributing

Contributions are welcome. Please open an issue before submitting large changes.
