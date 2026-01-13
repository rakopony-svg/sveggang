import Foundation
import CoreData

@objc(WishlistItemEntity)
class WishlistItemEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var photoData: Data?
    @NSManaged var originalPrice: Double
    @NSManaged var currentPrice: Double
    @NSManaged var desiredPrice: Double
    @NSManaged var storeNote: String?
    @NSManaged var dateAdded: Date
    @NSManaged var note: String?
    @NSManaged var isBought: Bool
    @NSManaged var isArchived: Bool
    @NSManaged var category: CategoryEntity?
    @NSManaged var priceUpdates: NSOrderedSet?
    @NSManaged var tags: NSSet?
    @NSManaged var purchaseHistory: PurchaseHistoryEntity?
}

extension WishlistItemEntity: Identifiable {
    var priceUpdatesArray: [PriceUpdateEntity] {
        (priceUpdates?.array as? [PriceUpdateEntity]) ?? []
    }
    
    var tagsArray: [TagEntity] {
        (tags?.allObjects as? [TagEntity]) ?? []
    }

    var dropPercentage: Double {
        guard originalPrice > 0 else { return 0 }
        return max(0, min(1, (originalPrice - currentPrice) / originalPrice))
    }

    var savings: Double {
        max(0, originalPrice - currentPrice)
    }

    var reachedTarget: Bool {
        currentPrice <= desiredPrice
    }
    
    var minimumPriceSeen: Double {
        let prices = priceUpdatesArray.map { $0.price }
        return prices.min() ?? currentPrice
    }
}

