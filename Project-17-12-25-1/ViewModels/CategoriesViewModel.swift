import Foundation
import CoreData

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var categories: [CategoryEntity] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        load()
    }

    func load() {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        do {
            categories = try context.fetch(request)
        } catch {
            print("Category fetch error: \(error)")
        }
    }

    func add(name: String, icon: String, top: String, bottom: String) {
        let cat = CategoryEntity(context: context)
        cat.id = UUID()
        cat.name = name
        cat.iconName = icon
        cat.gradientTopColor = top
        cat.gradientBottomColor = bottom
        cat.sortOrder = Int16((categories.last?.sortOrder ?? 0) + 1)
        save()
        load()
    }

    func delete(_ category: CategoryEntity) {
        context.delete(category)
        save()
        load()
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        var updated = categories
        updated.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (idx, cat) in updated.enumerated() {
            cat.sortOrder = Int16(idx)
        }
        save()
        load()
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("Category save error: \(error)")
        }
    }
}

