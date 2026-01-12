import Foundation
import CoreData

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var periodComparison: PeriodComparison?
    @Published var yearlyReport: YearlyReport?
    @Published var trackingEfficiency: TrackingEfficiency?
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    private let context: NSManagedObjectContext
    private let analyticsService = AdvancedAnalyticsService.shared
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadData()
    }
    
    func loadData() {
        let items = fetchAllItems()
        updatePeriodComparison(items: items)
        updateYearlyReport(items: items)
        updateTrackingEfficiency(items: items)
    }
    
    func updatePeriodComparison(items: [WishlistItemEntity]) {
        let calendar = Calendar.current
        let now = Date()
        
        // Текущий месяц
        let currentStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let currentEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: currentStart) ?? now
        
        // Предыдущий месяц
        let previousStart = calendar.date(byAdding: .month, value: -1, to: currentStart) ?? now
        let previousEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: previousStart) ?? now
        
        periodComparison = analyticsService.comparePeriods(
            currentStart: currentStart,
            currentEnd: currentEnd,
            previousStart: previousStart,
            previousEnd: previousEnd,
            items: items
        )
    }
    
    func updateYearlyReport(items: [WishlistItemEntity]) {
        yearlyReport = analyticsService.generateYearlyReport(year: selectedYear, items: items)
    }
    
    func updateTrackingEfficiency(items: [WishlistItemEntity]) {
        trackingEfficiency = analyticsService.analyzeTrackingEfficiency(items: items)
    }
    
    func exportCSV() -> String {
        let items = fetchAllItems()
        return analyticsService.exportToCSV(items: items)
    }
    
    private func fetchAllItems() -> [WishlistItemEntity] {
        let request = NSFetchRequest<WishlistItemEntity>(entityName: "WishlistItemEntity")
        request.predicate = NSPredicate(format: "isArchived == NO")
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
}
