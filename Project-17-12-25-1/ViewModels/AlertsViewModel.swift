import Foundation
import CoreData

enum AlertGroup: String, CaseIterable, Identifiable {
    case reachedTarget = "Reached target"
    case significantDrop = "Significant drop"
    case gettingCloser = "Getting closer"

    var id: String { rawValue }
}

@MainActor
final class AlertsViewModel: ObservableObject {
    @Published var grouped: [AlertGroup: [WishlistItemEntity]] = [:]
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        load()
    }

    func load() {
        let request = NSFetchRequest<WishlistItemEntity>(entityName: "WishlistItemEntity")
        request.predicate = NSPredicate(format: "isArchived == NO")
        do {
            let items = try context.fetch(request)
            grouped = Dictionary(grouping: items) { item in
                if item.reachedTarget { return .reachedTarget }
                if item.dropPercentage > 0.25 { return .significantDrop }
                return .gettingCloser
            }
        } catch {
            print("Alert fetch error: \(error)")
        }
    }
}

