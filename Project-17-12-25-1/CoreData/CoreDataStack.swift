import Foundation
import CoreData

final class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }

    private init(inMemory: Bool = false) {
        let model = CoreDataStack.buildModel()
        container = NSPersistentContainer(name: "PriceDropWishlistManager", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }
}

// MARK: - Model builder
private extension CoreDataStack {
    static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Category
        let category = NSEntityDescription()
        category.name = "CategoryEntity"
        category.managedObjectClassName = String(describing: CategoryEntity.self)

        let categoryId = NSAttributeDescription()
        categoryId.name = "id"
        categoryId.attributeType = .UUIDAttributeType
        categoryId.isOptional = false

        let categoryName = NSAttributeDescription()
        categoryName.name = "name"
        categoryName.attributeType = .stringAttributeType
        categoryName.isOptional = false

        let iconName = NSAttributeDescription()
        iconName.name = "iconName"
        iconName.attributeType = .stringAttributeType
        iconName.isOptional = false

        let gradientTop = NSAttributeDescription()
        gradientTop.name = "gradientTopColor"
        gradientTop.attributeType = .stringAttributeType
        gradientTop.isOptional = false

        let gradientBottom = NSAttributeDescription()
        gradientBottom.name = "gradientBottomColor"
        gradientBottom.attributeType = .stringAttributeType
        gradientBottom.isOptional = false

        let sortOrder = NSAttributeDescription()
        sortOrder.name = "sortOrder"
        sortOrder.attributeType = .integer16AttributeType
        sortOrder.defaultValue = 0

        category.properties = [categoryId, categoryName, iconName, gradientTop, gradientBottom, sortOrder]

        // WishlistItem
        let item = NSEntityDescription()
        item.name = "WishlistItemEntity"
        item.managedObjectClassName = String(describing: WishlistItemEntity.self)

        let itemId = NSAttributeDescription()
        itemId.name = "id"
        itemId.attributeType = .UUIDAttributeType
        itemId.isOptional = false

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false

        let photoData = NSAttributeDescription()
        photoData.name = "photoData"
        photoData.attributeType = .binaryDataAttributeType
        photoData.allowsExternalBinaryDataStorage = true
        photoData.isOptional = true

        let originalPrice = NSAttributeDescription()
        originalPrice.name = "originalPrice"
        originalPrice.attributeType = .doubleAttributeType

        let currentPrice = NSAttributeDescription()
        currentPrice.name = "currentPrice"
        currentPrice.attributeType = .doubleAttributeType

        let desiredPrice = NSAttributeDescription()
        desiredPrice.name = "desiredPrice"
        desiredPrice.attributeType = .doubleAttributeType

        let storeNote = NSAttributeDescription()
        storeNote.name = "storeNote"
        storeNote.attributeType = .stringAttributeType
        storeNote.isOptional = true

        let dateAdded = NSAttributeDescription()
        dateAdded.name = "dateAdded"
        dateAdded.attributeType = .dateAttributeType

        let note = NSAttributeDescription()
        note.name = "note"
        note.attributeType = .stringAttributeType
        note.isOptional = true

        let isBought = NSAttributeDescription()
        isBought.name = "isBought"
        isBought.attributeType = .booleanAttributeType
        isBought.defaultValue = false

        let isArchived = NSAttributeDescription()
        isArchived.name = "isArchived"
        isArchived.attributeType = .booleanAttributeType
        isArchived.defaultValue = false

        let itemCategory = NSRelationshipDescription()
        itemCategory.name = "category"
        itemCategory.destinationEntity = category
        itemCategory.minCount = 0
        itemCategory.maxCount = 1
        itemCategory.deleteRule = .nullifyDeleteRule

        let priceUpdates = NSRelationshipDescription()
        priceUpdates.name = "priceUpdates"
        priceUpdates.destinationEntity = nil
        priceUpdates.minCount = 0
        priceUpdates.maxCount = 0
        priceUpdates.deleteRule = .cascadeDeleteRule
        priceUpdates.isOrdered = true

        let itemTags = NSRelationshipDescription()
        itemTags.name = "tags"
        itemTags.destinationEntity = nil
        itemTags.minCount = 0
        itemTags.maxCount = 0
        itemTags.deleteRule = .nullifyDeleteRule

        let purchaseHistory = NSRelationshipDescription()
        purchaseHistory.name = "purchaseHistory"
        purchaseHistory.destinationEntity = nil
        purchaseHistory.minCount = 0
        purchaseHistory.maxCount = 1
        purchaseHistory.deleteRule = .cascadeDeleteRule

        item.properties = [
            itemId, nameAttr, photoData, originalPrice, currentPrice, desiredPrice, storeNote,
            dateAdded, note, isBought, isArchived, itemCategory, priceUpdates, itemTags, purchaseHistory
        ]

        // PriceUpdate
        let update = NSEntityDescription()
        update.name = "PriceUpdateEntity"
        update.managedObjectClassName = String(describing: PriceUpdateEntity.self)

        let updateId = NSAttributeDescription()
        updateId.name = "id"
        updateId.attributeType = .UUIDAttributeType
        updateId.isOptional = false

        let updatePrice = NSAttributeDescription()
        updatePrice.name = "price"
        updatePrice.attributeType = .doubleAttributeType

        let updateDate = NSAttributeDescription()
        updateDate.name = "date"
        updateDate.attributeType = .dateAttributeType

        let updateItem = NSRelationshipDescription()
        updateItem.name = "item"
        updateItem.destinationEntity = item
        updateItem.minCount = 0
        updateItem.maxCount = 1
        updateItem.deleteRule = .nullifyDeleteRule

        update.properties = [updateId, updatePrice, updateDate, updateItem]

        // Tag Entity
        let tag = NSEntityDescription()
        tag.name = "TagEntity"
        tag.managedObjectClassName = String(describing: TagEntity.self)

        let tagId = NSAttributeDescription()
        tagId.name = "id"
        tagId.attributeType = .UUIDAttributeType
        tagId.isOptional = false

        let tagName = NSAttributeDescription()
        tagName.name = "name"
        tagName.attributeType = .stringAttributeType
        tagName.isOptional = false

        let tagColor = NSAttributeDescription()
        tagColor.name = "color"
        tagColor.attributeType = .stringAttributeType
        tagColor.isOptional = false

        let tagIconName = NSAttributeDescription()
        tagIconName.name = "iconName"
        tagIconName.attributeType = .stringAttributeType
        tagIconName.isOptional = false

        let tagCreatedAt = NSAttributeDescription()
        tagCreatedAt.name = "createdAt"
        tagCreatedAt.attributeType = .dateAttributeType

        let tagItems = NSRelationshipDescription()
        tagItems.name = "items"
        tagItems.destinationEntity = item
        tagItems.minCount = 0
        tagItems.maxCount = 0
        tagItems.deleteRule = .nullifyDeleteRule

        tag.properties = [tagId, tagName, tagColor, tagIconName, tagCreatedAt, tagItems]

        // Goal Entity
        let goal = NSEntityDescription()
        goal.name = "GoalEntity"
        goal.managedObjectClassName = String(describing: GoalEntity.self)

        let goalId = NSAttributeDescription()
        goalId.name = "id"
        goalId.attributeType = .UUIDAttributeType
        goalId.isOptional = false

        let goalTitle = NSAttributeDescription()
        goalTitle.name = "title"
        goalTitle.attributeType = .stringAttributeType
        goalTitle.isOptional = false

        let goalType = NSAttributeDescription()
        goalType.name = "type"
        goalType.attributeType = .stringAttributeType
        goalType.isOptional = false

        let goalTargetValue = NSAttributeDescription()
        goalTargetValue.name = "targetValue"
        goalTargetValue.attributeType = .doubleAttributeType

        let goalCurrentValue = NSAttributeDescription()
        goalCurrentValue.name = "currentValue"
        goalCurrentValue.attributeType = .doubleAttributeType

        let goalPeriod = NSAttributeDescription()
        goalPeriod.name = "period"
        goalPeriod.attributeType = .stringAttributeType
        goalPeriod.isOptional = false

        let goalStartDate = NSAttributeDescription()
        goalStartDate.name = "startDate"
        goalStartDate.attributeType = .dateAttributeType

        let goalEndDate = NSAttributeDescription()
        goalEndDate.name = "endDate"
        goalEndDate.attributeType = .dateAttributeType

        let goalIsCompleted = NSAttributeDescription()
        goalIsCompleted.name = "isCompleted"
        goalIsCompleted.attributeType = .booleanAttributeType
        goalIsCompleted.defaultValue = false

        let goalCreatedAt = NSAttributeDescription()
        goalCreatedAt.name = "createdAt"
        goalCreatedAt.attributeType = .dateAttributeType

        goal.properties = [goalId, goalTitle, goalType, goalTargetValue, goalCurrentValue, goalPeriod, goalStartDate, goalEndDate, goalIsCompleted, goalCreatedAt]

        // PurchaseHistory Entity
        let purchase = NSEntityDescription()
        purchase.name = "PurchaseHistoryEntity"
        purchase.managedObjectClassName = String(describing: PurchaseHistoryEntity.self)

        let purchaseId = NSAttributeDescription()
        purchaseId.name = "id"
        purchaseId.attributeType = .UUIDAttributeType
        purchaseId.isOptional = false

        let purchasePrice = NSAttributeDescription()
        purchasePrice.name = "purchasePrice"
        purchasePrice.attributeType = .doubleAttributeType

        let purchaseDate = NSAttributeDescription()
        purchaseDate.name = "purchaseDate"
        purchaseDate.attributeType = .dateAttributeType

        let minimumPriceSeen = NSAttributeDescription()
        minimumPriceSeen.name = "minimumPriceSeen"
        minimumPriceSeen.attributeType = .doubleAttributeType

        let minimumPriceDate = NSAttributeDescription()
        minimumPriceDate.name = "minimumPriceDate"
        minimumPriceDate.attributeType = .dateAttributeType
        minimumPriceDate.isOptional = true

        let purchaseOriginalPrice = NSAttributeDescription()
        purchaseOriginalPrice.name = "originalPrice"
        purchaseOriginalPrice.attributeType = .doubleAttributeType

        let purchaseNotes = NSAttributeDescription()
        purchaseNotes.name = "notes"
        purchaseNotes.attributeType = .stringAttributeType
        purchaseNotes.isOptional = true

        let purchaseItem = NSRelationshipDescription()
        purchaseItem.name = "item"
        purchaseItem.destinationEntity = item
        purchaseItem.minCount = 0
        purchaseItem.maxCount = 1
        purchaseItem.deleteRule = .nullifyDeleteRule

        purchase.properties = [purchaseId, purchasePrice, purchaseDate, minimumPriceSeen, minimumPriceDate, purchaseOriginalPrice, purchaseNotes, purchaseItem]

        // Relationships corrections
        priceUpdates.destinationEntity = update
        priceUpdates.inverseRelationship = updateItem
        updateItem.inverseRelationship = priceUpdates
        itemCategory.inverseRelationship = nil
        
        itemTags.destinationEntity = tag
        itemTags.inverseRelationship = tagItems
        tagItems.inverseRelationship = itemTags
        
        purchaseHistory.destinationEntity = purchase
        purchaseHistory.inverseRelationship = purchaseItem
        purchaseItem.inverseRelationship = purchaseHistory

        model.entities = [category, item, update, tag, goal, purchase]
        return model
    }
}

