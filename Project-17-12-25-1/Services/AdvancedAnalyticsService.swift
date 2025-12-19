import Foundation
import CoreData

/// Сервис для детальной аналитики и отчетов
@MainActor
final class AdvancedAnalyticsService {
    static let shared = AdvancedAnalyticsService()
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = CoreDataStack.shared.context
    }
    
    // MARK: - Period Comparison
    
    /// Сравнение текущего периода с предыдущим
    func comparePeriods(
        currentStart: Date,
        currentEnd: Date,
        previousStart: Date,
        previousEnd: Date,
        items: [WishlistItemEntity]
    ) -> PeriodComparison {
        let currentItems = items.filter { item in
            item.dateAdded >= currentStart && item.dateAdded <= currentEnd
        }
        
        let previousItems = items.filter { item in
            item.dateAdded >= previousStart && item.dateAdded <= previousEnd
        }
        
        let currentSavings = currentItems.reduce(0) { $0 + $1.savings }
        let previousSavings = previousItems.reduce(0) { $0 + $1.savings }
        
        let currentUpdates = currentItems.reduce(0) { $0 + Double($1.priceUpdatesArray.count) }
        let previousUpdates = previousItems.reduce(0) { $0 + Double($1.priceUpdatesArray.count) }
        
        let currentTargets = currentItems.filter { $0.reachedTarget }.count
        let previousTargets = previousItems.filter { $0.reachedTarget }.count
        
        return PeriodComparison(
            currentPeriod: AnalyticsPeriod(
                totalSavings: currentSavings,
                totalItems: currentItems.count,
                totalUpdates: Int(currentUpdates),
                targetsReached: currentTargets,
                averageDrop: currentItems.isEmpty ? 0 : currentItems.reduce(0) { $0 + $1.dropPercentage } / Double(currentItems.count)
            ),
            previousPeriod: AnalyticsPeriod(
                totalSavings: previousSavings,
                totalItems: previousItems.count,
                totalUpdates: Int(previousUpdates),
                targetsReached: previousTargets,
                averageDrop: previousItems.isEmpty ? 0 : previousItems.reduce(0) { $0 + $1.dropPercentage } / Double(previousItems.count)
            )
        )
    }
    
    /// Генерация годового отчета
    func generateYearlyReport(year: Int, items: [WishlistItemEntity]) -> YearlyReport {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? Date()
        
        let yearItems = items.filter { item in
            item.dateAdded >= startOfYear && item.dateAdded <= endOfYear
        }
        
        var monthlyData: [MonthlyData] = []
        for month in 1...12 {
            let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? Date()
            
            let monthItems = yearItems.filter { item in
                item.dateAdded >= monthStart && item.dateAdded <= monthEnd
            }
            
            monthlyData.append(MonthlyData(
                month: month,
                monthName: calendar.monthSymbols[month - 1],
                totalSavings: monthItems.reduce(0) { $0 + $1.savings },
                itemsAdded: monthItems.count,
                targetsReached: monthItems.filter { $0.reachedTarget }.count
            ))
        }
        
        return YearlyReport(
            year: year,
            totalSavings: yearItems.reduce(0) { $0 + $1.savings },
            totalItems: yearItems.count,
            totalTargetsReached: yearItems.filter { $0.reachedTarget }.count,
            bestMonth: monthlyData.max { $0.totalSavings < $1.totalSavings },
            monthlyData: monthlyData
        )
    }
    
    /// Анализ эффективности отслеживания
    func analyzeTrackingEfficiency(items: [WishlistItemEntity]) -> TrackingEfficiency {
        var totalItems = 0
        var itemsWithUpdates = 0
        var itemsWithTargets = 0
        var itemsReachedTargets = 0
        var totalUpdateCount = 0
        var averageDaysToTarget: Double = 0
        
        for item in items where !item.isArchived {
            totalItems += 1
            
            if !item.priceUpdatesArray.isEmpty {
                itemsWithUpdates += 1
                totalUpdateCount += item.priceUpdatesArray.count
            }
            
            if item.desiredPrice > 0 {
                itemsWithTargets += 1
                if item.reachedTarget {
                    itemsReachedTargets += 1
                    if let firstUpdate = item.priceUpdatesArray.first,
                       let lastUpdate = item.priceUpdatesArray.last {
                        let days = Calendar.current.dateComponents([.day], from: firstUpdate.date, to: lastUpdate.date).day ?? 0
                        averageDaysToTarget += Double(days)
                    }
                }
            }
        }
        
        return TrackingEfficiency(
            totalItems: totalItems,
            itemsWithUpdates: itemsWithUpdates,
            itemsWithTargets: itemsWithTargets,
            itemsReachedTargets: itemsReachedTargets,
            averageUpdatesPerItem: totalItems > 0 ? Double(totalUpdateCount) / Double(totalItems) : 0,
            targetReachRate: itemsWithTargets > 0 ? Double(itemsReachedTargets) / Double(itemsWithTargets) : 0,
            averageDaysToTarget: itemsReachedTargets > 0 ? averageDaysToTarget / Double(itemsReachedTargets) : 0
        )
    }
    
    /// Экспорт данных в CSV
    func exportToCSV(items: [WishlistItemEntity]) -> String {
        var csv = "Name,Original Price,Current Price,Desired Price,Drop %,Savings,Target Reached,Category,Date Added\n"
        
        for item in items {
            let name = item.name.replacingOccurrences(of: ",", with: ";")
            let category = item.category?.name ?? "Uncategorized"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            csv += "\(name),\(item.originalPrice),\(item.currentPrice),\(item.desiredPrice),\(item.dropPercentage * 100),\(item.savings),\(item.reachedTarget),\(category),\(dateFormatter.string(from: item.dateAdded))\n"
        }
        
        return csv
    }
}

// MARK: - Models

struct PeriodComparison {
    let currentPeriod: AnalyticsPeriod
    let previousPeriod: AnalyticsPeriod
    
    var savingsChange: Double {
        currentPeriod.totalSavings - previousPeriod.totalSavings
    }
    
    var savingsChangePercent: Double {
        guard previousPeriod.totalSavings > 0 else { return 0 }
        return (savingsChange / previousPeriod.totalSavings) * 100
    }
    
    var itemsChange: Int {
        currentPeriod.totalItems - previousPeriod.totalItems
    }
}

struct AnalyticsPeriod {
    let totalSavings: Double
    let totalItems: Int
    let totalUpdates: Int
    let targetsReached: Int
    let averageDrop: Double
}

struct YearlyReport {
    let year: Int
    let totalSavings: Double
    let totalItems: Int
    let totalTargetsReached: Int
    let bestMonth: MonthlyData?
    let monthlyData: [MonthlyData]
}

struct MonthlyData {
    let month: Int
    let monthName: String
    let totalSavings: Double
    let itemsAdded: Int
    let targetsReached: Int
}

struct TrackingEfficiency {
    let totalItems: Int
    let itemsWithUpdates: Int
    let itemsWithTargets: Int
    let itemsReachedTargets: Int
    let averageUpdatesPerItem: Double
    let targetReachRate: Double
    let averageDaysToTarget: Double
}
