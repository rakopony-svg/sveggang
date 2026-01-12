import SwiftUI
import Charts

struct PatternAnalyticsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: WishlistItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateAdded", ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var items: FetchedResults<WishlistItemEntity>
    
    @State private var bestDays: [DayPattern] = []
    @State private var bestMonths: [MonthPattern] = []
    @State private var seasonality: [CategorySeasonality] = []
    @State private var recommendations: [PurchaseRecommendation] = []
    
    private let analyzer = PurchasePatternAnalyzer.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    recommendationsSection
                    bestDaysSection
                    bestMonthsSection
                    seasonalitySection
                }
                .padding()
            }
            .background(ThemeManager.shared.currentTheme.background.ignoresSafeArea())
            .navigationTitle("Purchase Patterns")
            .onAppear {
                analyzePatterns()
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if recommendations.isEmpty {
                Text("No recommendations yet. Keep tracking to get personalized insights!")
                    .font(.subheadline)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    .padding()
            } else {
                ForEach(recommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
        .themedCard()
    }
    
    private var bestDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Days for Price Drops")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if bestDays.isEmpty {
                Text("Not enough data yet")
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            } else {
                Chart(bestDays.prefix(7), id: \.dayOfWeek) { day in
                    BarMark(
                        x: .value("Day", day.dayName),
                        y: .value("Drops", day.dropCount)
                    )
                    .foregroundStyle(ThemeManager.shared.currentTheme.gradient)
                }
                .frame(height: 200)
            }
        }
        .themedCard()
    }
    
    private var bestMonthsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Months for Deals")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if bestMonths.isEmpty {
                Text("Not enough data yet")
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            } else {
                Chart(bestMonths, id: \.month) { month in
                    BarMark(
                        x: .value("Month", month.monthName),
                        y: .value("Drops", month.dropCount)
                    )
                    .foregroundStyle(ThemeManager.shared.currentTheme.accent)
                }
                .frame(height: 200)
            }
        }
        .themedCard()
    }
    
    private var seasonalitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Seasonality")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if seasonality.isEmpty {
                Text("Not enough data yet")
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            } else {
                ForEach(seasonality, id: \.categoryName) { cat in
                    HStack {
                        Text(cat.categoryName)
                            .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Best: \(cat.bestMonthName)")
                                .font(.caption)
                                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                            Text("\(cat.totalDrops) drops")
                                .font(.caption)
                                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                        }
                    }
                    .padding()
                    .background(ThemeManager.shared.currentTheme.card.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .themedCard()
    }
    
    private func analyzePatterns() {
        let itemsArray = Array(items)
        bestDays = analyzer.analyzeBestDaysOfWeek(for: itemsArray)
        bestMonths = analyzer.analyzeBestMonths(for: itemsArray)
        seasonality = analyzer.analyzeSeasonalityByCategory(for: itemsArray)
        recommendations = analyzer.generateRecommendations(for: itemsArray)
    }
}

struct RecommendationCard: View {
    let recommendation: PurchaseRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForType(recommendation.type))
                .font(.title2)
                .foregroundStyle(colorForPriority(recommendation.priority))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.headline)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                Text(recommendation.message)
                    .font(.subheadline)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(ThemeManager.shared.currentTheme.card.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func iconForType(_ type: PurchaseRecommendation.RecommendationType) -> String {
        switch type {
        case .bestDay: return "calendar"
        case .seasonal: return "leaf.fill"
        case .itemNearTarget: return "target"
        case .priceDrop: return "arrow.down.circle.fill"
        }
    }
    
    private func colorForPriority(_ priority: PurchaseRecommendation.Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

#Preview {
    PatternAnalyticsView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}
