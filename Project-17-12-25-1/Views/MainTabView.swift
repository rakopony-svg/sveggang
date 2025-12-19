import SwiftUI

struct MainTabView: View {
    @State private var showSplash = true
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        ZStack {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                AlertsListView()
                    .tabItem {
                        Label("Alerts", systemImage: "bell.badge.fill")
                    }
                SavedMoneyOverviewView()
                    .tabItem {
                        Label("Savings", systemImage: "chart.pie.fill")
                    }
                GoalsView()
                    .tabItem {
                        Label("Goals", systemImage: "target")
                    }
                PatternAnalyticsView()
                    .tabItem {
                        Label("Patterns", systemImage: "chart.line.uptrend.xyaxis")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            if showSplash {
                SplashScreenView(isActive: $showSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}

