import Foundation
import SwiftUI
import CoreData

@MainActor
final class ItemFormViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var photoData: Data?
    @Published var originalPrice: Double = 0
    @Published var currentPrice: Double = 0
    @Published var desiredPrice: Double = 0
    @Published var storeNote: String = ""
    @Published var note: String = ""
    @Published var dateAdded: Date = .now
    @Published var category: CategoryEntity?
    @Published var isEditing: Bool = false

    private let context: NSManagedObjectContext
    var item: WishlistItemEntity?

    init(context: NSManagedObjectContext, item: WishlistItemEntity? = nil) {
        self.context = context
        self.item = item
        if let item { populate(from: item) }
    }

    func save() {
        let target = item ?? WishlistItemEntity(context: context)
        if item == nil {
            target.id = UUID()
        }
        target.name = name
        target.photoData = photoData
        target.originalPrice = originalPrice
        target.currentPrice = currentPrice
        target.desiredPrice = desiredPrice
        target.storeNote = storeNote.isEmpty ? nil : storeNote
        target.dateAdded = dateAdded
        target.note = note.isEmpty ? nil : note
        target.category = category
        target.isArchived = false
        target.isBought = false

        if item == nil {
            let update = PriceUpdateEntity(context: context)
            update.id = UUID()
            update.price = currentPrice
            update.date = Date()
            update.item = target
            let mutable = target.mutableOrderedSetValue(forKey: "priceUpdates")
            mutable.add(update)
        }

        do {
            try context.save()
            item = target
        } catch {
            print("Save error: \(error)")
        }
    }

    private func populate(from item: WishlistItemEntity) {
        name = item.name
        photoData = item.photoData
        originalPrice = item.originalPrice
        currentPrice = item.currentPrice
        desiredPrice = item.desiredPrice
        storeNote = item.storeNote ?? ""
        dateAdded = item.dateAdded
        note = item.note ?? ""
        category = item.category
        isEditing = true
    }
}

