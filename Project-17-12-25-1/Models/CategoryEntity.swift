import Foundation
import CoreData

@objc(CategoryEntity)
class CategoryEntity: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var iconName: String
    @NSManaged var gradientTopColor: String
    @NSManaged var gradientBottomColor: String
    @NSManaged var sortOrder: Int16
}

