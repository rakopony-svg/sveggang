import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("currencyCode") private var currency = Locale.current.currency?.identifier ?? "USD"
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var remindersEnabled = false
    @State private var showResetConfirmation = false
    @Environment(\.managedObjectContext) private var context
    private let currencies: [String] = Locale.commonISOCurrencyCodes.sorted()

    var body: some View {
        NavigationStack {
            Form {
                Section("Currency") {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }
                Section("Theme") {
                    Picker("Theme", selection: $themeManager.currentTheme) {
                        Text("Light").tag(AppTheme.luminousLight)
                        Text("Dark").tag(AppTheme.velvetDark)
                    }
                    .onChange(of: themeManager.currentTheme) { _ in
                        // Дополнительная защита - гарантируем сохранение
                        themeManager.saveTheme()
                    }
                }
                Section("Price Tracking") {
                    Toggle("Auto-track prices", isOn: Binding(
                        get: { PriceTrackingService.shared.isTracking },
                        set: { newValue in
                            if newValue {
                                PriceTrackingService.shared.startTracking()
                            } else {
                                PriceTrackingService.shared.stopTracking()
                            }
                        }
                    ))
                    
                    if let lastUpdate = PriceTrackingService.shared.lastUpdateDate {
                        HStack {
                            Text("Last update")
                            Spacer()
                            Text(lastUpdate.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Reminders") {
                    Toggle("Check prices weekly", isOn: $remindersEnabled)
                }
                
                Section("Data") {
                    NavigationLink("Manage categories") {
                        CategoriesManagerView()
                    }
                    NavigationLink("Manage tags") {
                        TagsManagerView()
                    }
                    NavigationLink("Export & Reports") {
                        ExportReportsView()
                    }
                    NavigationLink("Advanced Analytics") {
                        AdvancedAnalyticsView()
                    }
                    NavigationLink("Purchase History") {
                        PurchaseHistoryView()
                    }
                    NavigationLink("Wishlist Map") {
                        WishlistMapView()
                    }
                    Button("Full data reset", role: .destructive) {
                        showResetConfirmation = true
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will permanently delete all your wishlist items, categories, and price history. This action cannot be undone.")
            }
        }
    }
    
    private func resetAllData() {
        let request1 = NSFetchRequest<WishlistItemEntity>(entityName: "WishlistItemEntity")
        let request2 = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        
        do {
            let items = try context.fetch(request1)
            let categories = try context.fetch(request2)
            
            items.forEach { context.delete($0) }
            categories.forEach { context.delete($0) }
            
            try context.save()
        } catch {
            print("Reset error: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}

