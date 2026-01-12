import Foundation
import CoreData

@MainActor
final class TagsViewModel: ObservableObject {
    @Published var tags: [TagEntity] = []
    @Published var selectedTags: Set<UUID> = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadTags()
    }
    
    func loadTags() {
        let request = NSFetchRequest<TagEntity>(entityName: "TagEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        do {
            tags = try context.fetch(request)
        } catch {
            print("Failed to load tags: \(error)")
        }
    }
    
    func createTag(name: String, color: String = "#8EC5FC", iconName: String = "tag.fill") {
        let tag = TagEntity(context: context)
        tag.id = UUID()
        tag.name = name
        tag.color = color
        tag.iconName = iconName
        tag.createdAt = Date()
        
        do {
            try context.save()
            loadTags()
        } catch {
            print("Failed to create tag: \(error)")
        }
    }
    
    func deleteTag(_ tag: TagEntity) {
        context.delete(tag)
        do {
            try context.save()
            loadTags()
        } catch {
            print("Failed to delete tag: \(error)")
        }
    }
    
    func addTag(_ tag: TagEntity, to item: WishlistItemEntity) {
        let mutableSet = item.mutableSetValue(forKey: "tags")
        mutableSet.add(tag)
        
        do {
            try context.save()
        } catch {
            print("Failed to add tag: \(error)")
        }
    }
    
    func removeTag(_ tag: TagEntity, from item: WishlistItemEntity) {
        let mutableSet = item.mutableSetValue(forKey: "tags")
        mutableSet.remove(tag)
        
        do {
            try context.save()
        } catch {
            print("Failed to remove tag: \(error)")
        }
    }
}
