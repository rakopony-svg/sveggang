// Для Мирона

import SwiftUI

@main
struct PriceDropWishlistManagerApp: App {
    @StateObject private var coreDataStack = CoreDataStack.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, coreDataStack.context)
                .environmentObject(coreDataStack)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.systemScheme)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                coreDataStack.save()
            }
        }
    }

}

