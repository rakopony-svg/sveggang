import Foundation
import CoreData

@objc(TagEntity)
class TagEntity: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var color: String // Hex color
    @NSManaged var iconName: String
    @NSManaged var createdAt: Date
    @NSManaged var items: NSSet?
}

extension TagEntity {
    var itemsArray: [WishlistItemEntity] {
        (items?.allObjects as? [WishlistItemEntity]) ?? []
    }
    
    var itemCount: Int {
        itemsArray.count
    }
}
