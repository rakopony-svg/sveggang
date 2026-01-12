import SwiftUI

struct AlertsListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: WishlistItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateAdded", ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var items: FetchedResults<WishlistItemEntity>
    @State private var smartAlerts: [SmartAlert] = []
    @State private var showSmartAlerts = true

    var body: some View {
        NavigationStack {
            let grouped = groupedItems
            Group {
                if grouped.isEmpty && smartAlerts.isEmpty {
                    emptyState
                } else {
                    List {
                        // Умные алерты
                        if showSmartAlerts && !smartAlerts.isEmpty {
                            Section {
                                ForEach(smartAlerts) { alert in
                                    NavigationLink {
                                        ItemDetailView(item: alert.item)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Image(systemName: iconForAlert(alert.type))
                                                        .foregroundStyle(colorForPriority(alert.priority))
                                                    Text(alert.title)
                                                        .font(.headline)
                                                        .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                                                }
                                                Text(alert.message)
                                                    .font(.subheadline)
                                                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                                                Text(alert.item.name)
                                                    .font(.caption)
                                                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary.opacity(0.7))
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                    Text("Smart Alerts")
                                }
                            }
                        }
                        
                        // Обычные алерты
                        ForEach(AlertGroup.allCases) { group in
                            if let list = grouped[group], !list.isEmpty {
                                Section(group.rawValue) {
                                    ForEach(list, id: \.id) { item in
                                        NavigationLink {
                                            ItemDetailView(item: item)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(item.name).font(.headline)
                                                        .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                                                    Text("-\(item.dropPercentage.percentString) • \(item.currentPrice.currency)")
                                                        .font(.subheadline).foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                                                }
                                                Spacer()
                                                if group == .reachedTarget {
                                                    Image(systemName: "sparkles")
                                                        .foregroundStyle(.yellow)
                                                        .transition(.scale)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Price Drop Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle("Smart", isOn: $showSmartAlerts)
                        .toggleStyle(.switch)
                }
            }
            .onAppear {
                loadSmartAlerts()
            }
        }
    }
    
    private func loadSmartAlerts() {
        smartAlerts = SmartAlertsService.shared.generateSmartAlerts(for: Array(items))
    }
    
    private func iconForAlert(_ type: SmartAlert.AlertType) -> String {
        switch type {
        case .rapidPriceDrop: return "arrow.down.circle.fill"
        case .nearTarget: return "target"
        case .targetReached: return "sparkles"
        case .priceStabilized: return "chart.line.flattrend.xyaxis"
        case .seasonalSale: return "calendar.badge.clock"
        }
    }
    
    private func colorForPriority(_ priority: SmartAlert.AlertPriority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }

    private var groupedItems: [AlertGroup: [WishlistItemEntity]] {
        let base = Array(items)
        return Dictionary(grouping: base) { item in
            if item.reachedTarget { return .reachedTarget }
            if item.dropPercentage > 0.25 { return .significantDrop }
            return .gettingCloser
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(ThemeManager.shared.currentTheme.accent)
            Text("No alerts yet")
                .font(.title3.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            Text("Add items and update prices to see celebrations here.")
                .font(.subheadline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeManager.shared.currentTheme.background.ignoresSafeArea())
    }
}

#Preview {
    AlertsListView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}

