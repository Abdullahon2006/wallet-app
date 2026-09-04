import SwiftUI
import SwiftData

/// The main entry point for the Vault app.
@main
struct VaultApp: App {
    @State private var lockManager = LockManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CardItem.self,
            Category.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        // Apply file protection to the store
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Set NSFileProtectionComplete on the store file
            let storeURL = modelConfiguration.url
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: storeURL.path
            )

            // Ensure encryption key exists in Keychain
            _ = KeychainManager.shared.getOrCreateEncryptionKey()

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(lockManager)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                lockManager.appDidEnterBackground()
            case .active:
                lockManager.appDidBecomeActive()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
