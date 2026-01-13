import Foundation
import CoreData

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var items: [WishlistItemEntity] = []
    @Published var totalSaved: Double = 0
    @Published var estimatedValue: Double = 0
    @Published var averageDrop: Double = 0

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        load()
    }

    func load() {
        let request = NSFetchRequest<WishlistItemEntity>(entityName: "WishlistItemEntity")
        request.predicate = NSPredicate(format: "isArchived == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        do {
            items = try context.fetch(request)
            recalc()
        } catch {
            print("Fetch error: \(error)")
        }
    }

    private func recalc() {
        estimatedValue = items.reduce(0) { $0 + $1.currentPrice }
        totalSaved = items.reduce(0) { $0 + $1.savings }
        let drops = items.map { $0.dropPercentage }
        averageDrop = drops.isEmpty ? 0 : drops.reduce(0, +) / Double(drops.count)
    }
}

