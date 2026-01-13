import Foundation
import CoreData

/// Сервис для анализа паттернов покупок и рекомендаций
@MainActor
final class PurchasePatternAnalyzer {
    static let shared = PurchasePatternAnalyzer()
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = CoreDataStack.shared.context
    }
    
    // MARK: - Pattern Analysis
    
    /// Анализ лучших дней недели для покупок
    func analyzeBestDaysOfWeek(for items: [WishlistItemEntity]) -> [DayPattern] {
        var dayStats: [Int: (count: Int, totalDrop: Double)] = [:]
        
        for item in items {
            let updates = item.priceUpdatesArray.sorted { $0.date < $1.date }
            guard updates.count >= 2 else { continue }
            
            for i in 1..<updates.count {
                if updates[i].price < updates[i-1].price {
                    let calendar = Calendar.current
                    let dayOfWeek = calendar.component(.weekday, from: updates[i].date)
                    let drop = updates[i-1].price - updates[i].price
                    
                    if dayStats[dayOfWeek] == nil {
                        dayStats[dayOfWeek] = (0, 0)
                    }
                    dayStats[dayOfWeek]?.count += 1
                    dayStats[dayOfWeek]?.totalDrop += drop
                }
            }
        }
        
        return dayStats.map { day, stats in
            DayPattern(
                dayOfWeek: day,
                dropCount: stats.count,
                averageDrop: stats.totalDrop / Double(stats.count),
                dayName: Calendar.current.weekdaySymbols[day - 1]
            )
        }.sorted { $0.dropCount > $1.dropCount }
    }
    
    /// Анализ лучших месяцев для покупок
    func analyzeBestMonths(for items: [WishlistItemEntity]) -> [MonthPattern] {
        var monthStats: [Int: (count: Int, totalDrop: Double)] = [:]
        
        for item in items {
            let updates = item.priceUpdatesArray.sorted { $0.date < $1.date }
            guard updates.count >= 2 else { continue }
            
            for i in 1..<updates.count {
                if updates[i].price < updates[i-1].price {
                    let calendar = Calendar.current
                    let month = calendar.component(.month, from: updates[i].date)
                    let drop = updates[i-1].price - updates[i].price
                    
                    if monthStats[month] == nil {
                        monthStats[month] = (0, 0)
                    }
                    monthStats[month]?.count += 1
                    monthStats[month]?.totalDrop += drop
                }
            }
        }
        
        return monthStats.map { month, stats in
            MonthPattern(
                month: month,
                dropCount: stats.count,
                averageDrop: stats.totalDrop / Double(stats.count),
                monthName: Calendar.current.monthSymbols[month - 1]
            )
        }.sorted { $0.dropCount > $1.dropCount }
    }
    
    /// Анализ сезонности по категориям
    func analyzeSeasonalityByCategory(for items: [WishlistItemEntity]) -> [CategorySeasonality] {
        var categoryStats: [String: [Int: (count: Int, totalDrop: Double)]] = [:]
        
        for item in items {
            let categoryName = item.category?.name ?? "Uncategorized"
            let updates = item.priceUpdatesArray.sorted { $0.date < $1.date }
            guard updates.count >= 2 else { continue }
            
            if categoryStats[categoryName] == nil {
                categoryStats[categoryName] = [:]
            }
            
            for i in 1..<updates.count {
                if updates[i].price < updates[i-1].price {
                    let calendar = Calendar.current
                    let month = calendar.component(.month, from: updates[i].date)
                    let drop = updates[i-1].price - updates[i].price
                    
                    if categoryStats[categoryName]?[month] == nil {
                        categoryStats[categoryName]?[month] = (0, 0)
                    }
                    categoryStats[categoryName]?[month]?.count += 1
                    categoryStats[categoryName]?[month]?.totalDrop += drop
                }
            }
        }
        
        return categoryStats.map { categoryName, monthData in
            let bestMonth = monthData.max { $0.value.count < $1.value.count }?.key ?? 1
            return CategorySeasonality(
                categoryName: categoryName,
                bestMonth: bestMonth,
                bestMonthName: Calendar.current.monthSymbols[bestMonth - 1],
                totalDrops: monthData.values.reduce(0) { $0 + $1.count }
            )
        }
    }
    
    /// Рекомендации на основе паттернов
    func generateRecommendations(for items: [WishlistItemEntity]) -> [PurchaseRecommendation] {
        var recommendations: [PurchaseRecommendation] = []
        
        let bestDays = analyzeBestDaysOfWeek(for: items)
        if let bestDay = bestDays.first {
            recommendations.append(
                PurchaseRecommendation(
                    type: .bestDay,
                    title: "Best Day to Check Prices",
                    message: "Based on your history, \(bestDay.dayName) is the best day for price drops",
                    priority: .medium
                )
            )
        }
        
        let bestMonths = analyzeBestMonths(for: items)
        let currentMonth = Calendar.current.component(.month, from: Date())
        if let bestMonth = bestMonths.first, bestMonth.month == currentMonth {
            recommendations.append(
                PurchaseRecommendation(
                    type: .seasonal,
                    title: "Seasonal Opportunity",
                    message: "\(bestMonth.monthName) is historically your best month for deals",
                    priority: .high
                )
            )
        }
        
        // Рекомендации по товарам
        let itemsNearTarget = items.filter { item in
            guard item.desiredPrice > 0 else { return false }
            let distance = item.currentPrice - item.desiredPrice
            return distance > 0 && distance <= item.currentPrice * 0.1
        }
        
        if let item = itemsNearTarget.first {
            recommendations.append(
                PurchaseRecommendation(
                    type: .itemNearTarget,
                    title: "Close to Target",
                    message: "\(item.name) is only \(item.currentPrice - item.desiredPrice) away from your target",
                    priority: .high,
                    itemId: item.id
                )
            )
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}

// MARK: - Models

struct DayPattern {
    let dayOfWeek: Int
    let dropCount: Int
    let averageDrop: Double
    let dayName: String
}

struct MonthPattern {
    let month: Int
    let dropCount: Int
    let averageDrop: Double
    let monthName: String
}

struct CategorySeasonality {
    let categoryName: String
    let bestMonth: Int
    let bestMonthName: String
    let totalDrops: Int
}

struct PurchaseRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let message: String
    let priority: Priority
    var itemId: UUID?
    
    enum RecommendationType {
        case bestDay
        case seasonal
        case itemNearTarget
        case priceDrop
    }
    
    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
}
