import Foundation
import CoreData

/// Сервис для управления историей покупок
@MainActor
final class PurchaseHistoryService {
    static let shared = PurchaseHistoryService()
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = CoreDataStack.shared.context
    }
    
    // MARK: - Purchase Recording
    
    /// Записать покупку товара
    func recordPurchase(
        for item: WishlistItemEntity,
        purchasePrice: Double,
        notes: String? = nil
    ) {
        // Проверяем, есть ли уже история покупки
        if let existing = item.purchaseHistory {
            existing.purchasePrice = purchasePrice
            existing.purchaseDate = Date()
            existing.notes = notes
        } else {
            let purchase = PurchaseHistoryEntity(context: context)
            purchase.id = UUID()
            purchase.item = item
            purchase.purchasePrice = purchasePrice
            purchase.purchaseDate = Date()
            purchase.originalPrice = item.originalPrice
            purchase.minimumPriceSeen = item.minimumPriceSeen
            purchase.minimumPriceDate = item.priceUpdatesArray.first(where: { $0.price == item.minimumPriceSeen })?.date
            purchase.notes = notes
        }
        
        item.isBought = true
        
        do {
            try context.save()
        } catch {
            print("Failed to record purchase: \(error)")
        }
    }
    
    /// Получить все покупки
    func getAllPurchases() -> [PurchaseHistoryEntity] {
        let request = NSFetchRequest<PurchaseHistoryEntity>(entityName: "PurchaseHistoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "purchaseDate", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch purchases: \(error)")
            return []
        }
    }
    
    /// Анализ упущенных возможностей
    func analyzeMissedOpportunities() -> MissedOpportunitiesAnalysis {
        let purchases = getAllPurchases()
        
        var totalMissedSavings: Double = 0
        var itemsWithMissedSavings: Int = 0
        var biggestMiss: PurchaseHistoryEntity?
        var biggestMissAmount: Double = 0
        
        for purchase in purchases {
            if purchase.couldHaveSavedMore {
                let missed = purchase.missedSavings
                totalMissedSavings += missed
                itemsWithMissedSavings += 1
                
                if missed > biggestMissAmount {
                    biggestMissAmount = missed
                    biggestMiss = purchase
                }
            }
        }
        
        return MissedOpportunitiesAnalysis(
            totalMissedSavings: totalMissedSavings,
            itemsWithMissedSavings: itemsWithMissedSavings,
            averageMissedSavings: itemsWithMissedSavings > 0 ? totalMissedSavings / Double(itemsWithMissedSavings) : 0,
            biggestMiss: biggestMiss,
            biggestMissAmount: biggestMissAmount
        )
    }
    
    /// Сравнение покупок
    func comparePurchases() -> PurchaseComparison {
        let purchases = getAllPurchases()
        
        let totalSpent = purchases.reduce(0) { $0 + $1.purchasePrice }
        let totalOriginal = purchases.reduce(0) { $0 + $1.originalPrice }
        let totalSavings = purchases.reduce(0) { $0 + $1.totalSavings }
        let totalMissed = purchases.reduce(0) { $0 + $1.missedSavings }
        
        return PurchaseComparison(
            totalPurchases: purchases.count,
            totalSpent: totalSpent,
            totalOriginalValue: totalOriginal,
            totalSavings: totalSavings,
            totalMissedSavings: totalMissed,
            averageSavingsPerPurchase: purchases.isEmpty ? 0 : totalSavings / Double(purchases.count),
            bestPurchase: purchases.max { $0.totalSavings < $1.totalSavings },
            worstPurchase: purchases.max { $0.missedSavings < $1.missedSavings }
        )
    }
    
    /// Статистика по купленным товарам
    func getPurchaseStatistics() -> PurchaseStatistics {
        let purchases = getAllPurchases()
        
        let calendar = Calendar.current
        let now = Date()
        let thisMonth = calendar.component(.month, from: now)
        let thisYear = calendar.component(.year, from: now)
        
        let thisMonthPurchases = purchases.filter { purchase in
            let month = calendar.component(.month, from: purchase.purchaseDate)
            let year = calendar.component(.year, from: purchase.purchaseDate)
            return month == thisMonth && year == thisYear
        }
        
        return PurchaseStatistics(
            totalPurchases: purchases.count,
            thisMonthPurchases: thisMonthPurchases.count,
            totalSpent: purchases.reduce(0) { $0 + $1.purchasePrice },
            thisMonthSpent: thisMonthPurchases.reduce(0) { $0 + $1.purchasePrice },
            totalSavings: purchases.reduce(0) { $0 + $1.totalSavings },
            thisMonthSavings: thisMonthPurchases.reduce(0) { $0 + $1.totalSavings }
        )
    }
}

// MARK: - Models

struct MissedOpportunitiesAnalysis {
    let totalMissedSavings: Double
    let itemsWithMissedSavings: Int
    let averageMissedSavings: Double
    let biggestMiss: PurchaseHistoryEntity?
    let biggestMissAmount: Double
}

struct PurchaseComparison {
    let totalPurchases: Int
    let totalSpent: Double
    let totalOriginalValue: Double
    let totalSavings: Double
    let totalMissedSavings: Double
    let averageSavingsPerPurchase: Double
    let bestPurchase: PurchaseHistoryEntity?
    let worstPurchase: PurchaseHistoryEntity?
}

struct PurchaseStatistics {
    let totalPurchases: Int
    let thisMonthPurchases: Int
    let totalSpent: Double
    let thisMonthSpent: Double
    let totalSavings: Double
    let thisMonthSavings: Double
}
