import Foundation
import CoreData

@objc(PurchaseHistoryEntity)
class PurchaseHistoryEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var purchasePrice: Double
    @NSManaged var purchaseDate: Date
    @NSManaged var minimumPriceSeen: Double
    @NSManaged var minimumPriceDate: Date?
    @NSManaged var originalPrice: Double
    @NSManaged var notes: String?
    @NSManaged var item: WishlistItemEntity?
}

extension PurchaseHistoryEntity {
    var missedSavings: Double {
        max(0, purchasePrice - minimumPriceSeen)
    }
    
    var totalSavings: Double {
        max(0, originalPrice - purchasePrice)
    }
    
    var couldHaveSavedMore: Bool {
        minimumPriceSeen < purchasePrice
    }
}
