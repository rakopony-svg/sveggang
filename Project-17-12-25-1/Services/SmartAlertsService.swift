import Foundation
import CoreData

/// Умная система алертов с анализом паттернов
@MainActor
final class SmartAlertsService {
    static let shared = SmartAlertsService()
    
    private init() {}
    
    /// Генерировать умные алерты на основе анализа данных
    func generateSmartAlerts(for items: [WishlistItemEntity]) -> [SmartAlert] {
        var alerts: [SmartAlert] = []
        
        for item in items where !item.isArchived && !item.isBought {
            // Анализ скорости падения цены
            if let velocityAlert = analyzePriceVelocity(for: item) {
                alerts.append(velocityAlert)
            }
            
            // Анализ приближения к цели
            if let proximityAlert = analyzeTargetProximity(for: item) {
                alerts.append(proximityAlert)
            }
            
            // Анализ лучшего времени для покупки
            if let timingAlert = analyzeBestBuyTime(for: item) {
                alerts.append(timingAlert)
            }
            
            // Анализ сезонности
            if let seasonalAlert = analyzeSeasonality(for: item) {
                alerts.append(seasonalAlert)
            }
        }
        
        return alerts.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    /// Анализ скорости падения цены
    private func analyzePriceVelocity(for item: WishlistItemEntity) -> SmartAlert? {
        let updates = item.priceUpdatesArray.sorted { $0.date < $1.date }
        guard updates.count >= 2 else { return nil }
        
        let recentUpdates = Array(updates.suffix(3))
        var totalDrop: Double = 0
        var totalDays: Double = 0
        
        for i in 1..<recentUpdates.count {
            let drop = recentUpdates[i-1].price - recentUpdates[i].price
            let days = recentUpdates[i].date.timeIntervalSince(recentUpdates[i-1].date) / 86400
            if days > 0 {
                totalDrop += drop
                totalDays += days
            }
        }
        
        guard totalDays > 0 else { return nil }
        let dailyDropRate = totalDrop / totalDays
        
        if dailyDropRate > item.currentPrice * 0.01 { // Падение больше 1% в день
            return SmartAlert(
                type: .rapidPriceDrop,
                item: item,
                title: "Rapid Price Drop Detected",
                message: "Price is dropping fast at \(dailyDropRate.currency) per day. Consider waiting.",
                priority: .high
            )
        }
        
        return nil
    }
    
    /// Анализ приближения к целевой цене
    private func analyzeTargetProximity(for item: WishlistItemEntity) -> SmartAlert? {
        guard item.desiredPrice > 0 else { return nil }
        
        let distance = item.currentPrice - item.desiredPrice
        let percentage = (distance / item.currentPrice) * 100
        
        if percentage <= 5 && percentage > 0 {
            return SmartAlert(
                type: .nearTarget,
                item: item,
                title: "Almost at Target Price",
                message: "Only \(distance.currency) away from your target. Great time to buy!",
                priority: .high
            )
        }
        
        if item.reachedTarget {
            return SmartAlert(
                type: .targetReached,
                item: item,
                title: "Target Price Reached! 🎉",
                message: "Price has reached your target of \(item.desiredPrice.currency). Time to celebrate!",
                priority: .critical
            )
        }
        
        return nil
    }
    
    /// Анализ лучшего времени для покупки
    private func analyzeBestBuyTime(for item: WishlistItemEntity) -> SmartAlert? {
        let updates = item.priceUpdatesArray.sorted { $0.date < $1.date }
        guard updates.count >= 3 else { return nil }
        
        // Анализируем паттерн: если цена стабилизировалась после падения
        let recent = Array(updates.suffix(3))
        let firstDrop = recent[0].price - recent[1].price
        let secondDrop = recent[1].price - recent[2].price
        
        // Если было падение, а потом стабилизация
        if firstDrop > 0 && abs(secondDrop) < item.currentPrice * 0.01 {
            return SmartAlert(
                type: .priceStabilized,
                item: item,
                title: "Price Stabilized After Drop",
                message: "Price has stabilized after recent drop. Good time to consider buying.",
                priority: .medium
            )
        }
        
        return nil
    }
    
    /// Анализ сезонности (базовая реализация)
    private func analyzeSeasonality(for item: WishlistItemEntity) -> SmartAlert? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        
        // Простая логика: если товар добавлен давно и сейчас сезон распродаж
        let daysSinceAdded = calendar.dateComponents([.day], from: item.dateAdded, to: Date()).day ?? 0
        
        // Черная пятница / Кибер понедельник (ноябрь)
        if month == 11 && daysSinceAdded > 30 {
            return SmartAlert(
                type: .seasonalSale,
                item: item,
                title: "Seasonal Sale Period",
                message: "We're in sale season. Prices may drop further. Monitor closely.",
                priority: .medium
            )
        }
        
        return nil
    }
}

// MARK: - Smart Alert Model

struct SmartAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let item: WishlistItemEntity
    let title: String
    let message: String
    let priority: AlertPriority
    
    enum AlertType {
        case rapidPriceDrop
        case nearTarget
        case targetReached
        case priceStabilized
        case seasonalSale
    }
    
    enum AlertPriority: Int {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
    }
}
