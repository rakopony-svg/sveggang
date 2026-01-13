import SwiftUI
import Charts

struct PurchaseHistoryView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var purchases: [PurchaseHistoryEntity] = []
    @State private var comparison: PurchaseComparison?
    @State private var statistics: PurchaseStatistics?
    @State private var missedOpportunities: MissedOpportunitiesAnalysis?
    
    private let purchaseService = PurchaseHistoryService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    statisticsSection
                    comparisonSection
                    missedOpportunitiesSection
                    purchasesList
                }
                .padding()
            }
            .background(ThemeManager.shared.currentTheme.background.ignoresSafeArea())
            .navigationTitle("Purchase History")
            .onAppear {
                loadData()
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if let stats = statistics {
                HStack(spacing: 12) {
                    statCard(title: "Total Purchases", value: "\(stats.totalPurchases)")
                    statCard(title: "This Month", value: "\(stats.thisMonthPurchases)")
                    statCard(title: "Total Spent", value: stats.totalSpent.currency)
                    statCard(title: "Total Saved", value: stats.totalSavings.currency)
                }
            }
        }
        .themedCard()
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ThemeManager.shared.currentTheme.card.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Purchase Comparison")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if let comp = comparison {
                VStack(spacing: 12) {
                    comparisonRow(title: "Total Spent", value: comp.totalSpent.currency)
                    comparisonRow(title: "Total Saved", value: comp.totalSavings.currency)
                    comparisonRow(title: "Missed Savings", value: comp.totalMissedSavings.currency, isWarning: true)
                    comparisonRow(title: "Avg Savings per Purchase", value: comp.averageSavingsPerPurchase.currency)
                }
            }
        }
        .themedCard()
    }
    
    private func comparisonRow(title: String, value: String, isWarning: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundStyle(isWarning ? .orange : ThemeManager.shared.currentTheme.textPrimary)
        }
        .padding(.vertical, 4)
    }
    
    private var missedOpportunitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Missed Opportunities")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if let missed = missedOpportunities {
                VStack(spacing: 12) {
                    Text("You could have saved an additional \(missed.totalMissedSavings.currency)")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    
                    if let biggest = missed.biggestMiss, let item = biggest.item {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Biggest Miss:")
                                .font(.caption)
                                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                            Text("\(item.name) - \(missed.biggestMissAmount.currency)")
                                .font(.headline)
                                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .themedCard()
    }
    
    private var purchasesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Purchases")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if purchases.isEmpty {
                Text("No purchases recorded yet")
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    .padding()
            } else {
                ForEach(purchases.prefix(10), id: \.id) { purchase in
                    if let item = purchase.item {
                        PurchaseRow(purchase: purchase, item: item)
                    }
                }
            }
        }
        .themedCard()
    }
    
    private func loadData() {
        purchases = purchaseService.getAllPurchases()
        comparison = purchaseService.comparePurchases()
        statistics = purchaseService.getPurchaseStatistics()
        missedOpportunities = purchaseService.analyzeMissedOpportunities()
    }
}

struct PurchaseRow: View {
    let purchase: PurchaseHistoryEntity
    let item: WishlistItemEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                Spacer()
                Text(purchase.purchasePrice.currency)
                    .font(.headline)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            }
            
            HStack {
                Label("Saved: \(purchase.totalSavings.currency)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                
                if purchase.couldHaveSavedMore {
                    Label("Missed: \(purchase.missedSavings.currency)", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Text(purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
        }
        .padding()
        .background(ThemeManager.shared.currentTheme.card.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    PurchaseHistoryView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}
