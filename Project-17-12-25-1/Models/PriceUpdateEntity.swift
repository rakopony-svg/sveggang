import Foundation
import CoreData

@objc(PriceUpdateEntity)
class PriceUpdateEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var price: Double
    @NSManaged var date: Date
    @NSManaged var item: WishlistItemEntity?
}

