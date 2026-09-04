import SwiftUI

/// Root view — gates access behind the lock screen, then shows the main tab view.
struct ContentView: View {
    @State private var lockManager = LockManager.shared
    @State private var selectedTab: Tab = .cards

    enum Tab: String, CaseIterable {
        case cards = "Cards"
        case categories = "Categories"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .cards:      return "creditcard.fill"
            case .categories: return "folder.fill"
            case .settings:   return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            if lockManager.isLocked {
                LockScreenView()
                    .transition(.opacity)
            } else {
                TabView(selection: $selectedTab) {
                    CardDeckView()
                        .tabItem {
                            Label(Tab.cards.rawValue, systemImage: Tab.cards.icon)
                        }
                        .tag(Tab.cards)

                    CategoriesListView()
                        .tabItem {
                            Label(Tab.categories.rawValue, systemImage: Tab.categories.icon)
                        }
                        .tag(Tab.categories)

                    SettingsView()
                        .tabItem {
                            Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                        }
                        .tag(Tab.settings)
                }
                .tint(Color(hex: "#7C3AED"))
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: lockManager.isLocked)
        .preferredColorScheme(.dark)
    }
}
