import Foundation
import CoreData

/// Сервис для управления целями и достижениями
@MainActor
final class GoalsService: ObservableObject {
    static let shared = GoalsService()
    
    @Published var goals: [GoalEntity] = []
    @Published var achievements: [Achievement] = []
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = CoreDataStack.shared.context
        loadGoals()
        checkAchievements()
    }
    
    // MARK: - Goals Management
    
    func loadGoals() {
        let request = NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        do {
            goals = try context.fetch(request)
            updateGoalProgress()
        } catch {
            print("Failed to load goals: \(error)")
        }
    }
    
    func createGoal(
        title: String,
        type: GoalEntity.GoalType,
        targetValue: Double,
        period: GoalEntity.Period
    ) {
        let goal = GoalEntity(context: context)
        goal.id = UUID()
        goal.title = title
        goal.type = type.rawValue
        goal.targetValue = targetValue
        goal.currentValue = 0
        goal.period = period.rawValue
        goal.createdAt = Date()
        
        let calendar = Calendar.current
        let now = Date()
        goal.startDate = now
        
        switch period {
        case .daily:
            goal.endDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case .weekly:
            goal.endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        case .monthly:
            goal.endDate = calendar.date(byAdding: .month, value: 1, to: now) ?? now
        case .yearly:
            goal.endDate = calendar.date(byAdding: .year, value: 1, to: now) ?? now
        }
        
        goal.isCompleted = false
        
        do {
            try context.save()
            loadGoals()
        } catch {
            print("Failed to create goal: \(error)")
        }
    }
    
    func deleteGoal(_ goal: GoalEntity) {
        context.delete(goal)
        do {
            try context.save()
            loadGoals()
        } catch {
            print("Failed to delete goal: \(error)")
        }
    }
    
    func updateGoalProgress() {
        let items = fetchAllItems()
        
        for goal in goals where !goal.isCompleted && goal.isActive {
            switch GoalEntity.GoalType(rawValue: goal.type) {
            case .savings:
                goal.currentValue = calculateSavingsForPeriod(goal: goal, items: items)
            case .updates:
                goal.currentValue = Double(calculateUpdatesForPeriod(goal: goal, items: items))
            case .targets:
                goal.currentValue = Double(calculateTargetsReachedForPeriod(goal: goal, items: items))
            case .none:
                break
            }
            
            if goal.currentValue >= goal.targetValue {
                goal.isCompleted = true
                checkAchievements()
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to update goals: \(error)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchAllItems() -> [WishlistItemEntity] {
        let request = NSFetchRequest<WishlistItemEntity>(entityName: "WishlistItemEntity")
        request.predicate = NSPredicate(format: "isArchived == NO")
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    private func calculateSavingsForPeriod(goal: GoalEntity, items: [WishlistItemEntity]) -> Double {
        let itemsInPeriod = items.filter { item in
            item.dateAdded >= goal.startDate && item.dateAdded <= goal.endDate
        }
        return itemsInPeriod.reduce(0) { $0 + $1.savings }
    }
    
    private func calculateUpdatesForPeriod(goal: GoalEntity, items: [WishlistItemEntity]) -> Int {
        var count = 0
        for item in items {
            let updates = item.priceUpdatesArray.filter { update in
                update.date >= goal.startDate && update.date <= goal.endDate
            }
            count += updates.count
        }
        return count
    }
    
    private func calculateTargetsReachedForPeriod(goal: GoalEntity, items: [WishlistItemEntity]) -> Int {
        let itemsInPeriod = items.filter { item in
            item.dateAdded >= goal.startDate && item.dateAdded <= goal.endDate
        }
        return itemsInPeriod.filter { $0.reachedTarget }.count
    }
    
    // MARK: - Achievements
    
    func checkAchievements() {
        let items = fetchAllItems()
        var newAchievements: [Achievement] = []
        
        // First Item Achievement
        if items.count >= 1 && !achievements.contains(where: { $0.id == "first_item" }) {
            newAchievements.append(Achievement(
                id: "first_item",
                title: "Getting Started",
                description: "Added your first item to wishlist",
                icon: "star.fill",
                unlockedAt: Date()
            ))
        }
        
        // 10 Items Achievement
        if items.count >= 10 && !achievements.contains(where: { $0.id == "ten_items" }) {
            newAchievements.append(Achievement(
                id: "ten_items",
                title: "Wishlist Master",
                description: "Added 10 items to your wishlist",
                icon: "star.circle.fill",
                unlockedAt: Date()
            ))
        }
        
        // First Target Reached
        let reachedTargets = items.filter { $0.reachedTarget }
        if reachedTargets.count >= 1 && !achievements.contains(where: { $0.id == "first_target" }) {
            newAchievements.append(Achievement(
                id: "first_target",
                title: "Target Achieved",
                description: "Reached your first target price",
                icon: "target",
                unlockedAt: Date()
            ))
        }
        
        // Savings Milestones
        let totalSavings = items.reduce(0) { $0 + $1.savings }
        if totalSavings >= 100 && !achievements.contains(where: { $0.id == "savings_100" }) {
            newAchievements.append(Achievement(
                id: "savings_100",
                title: "Smart Saver",
                description: "Saved $100 or more",
                icon: "dollarsign.circle.fill",
                unlockedAt: Date()
            ))
        }
        
        if totalSavings >= 500 && !achievements.contains(where: { $0.id == "savings_500" }) {
            newAchievements.append(Achievement(
                id: "savings_500",
                title: "Savings Champion",
                description: "Saved $500 or more",
                icon: "crown.fill",
                unlockedAt: Date()
            ))
        }
        
        // Streak Achievement
        let streak = calculateUpdateStreak(items: items)
        if streak >= 7 && !achievements.contains(where: { $0.id == "streak_7" }) {
            newAchievements.append(Achievement(
                id: "streak_7",
                title: "Consistent Tracker",
                description: "Updated prices for 7 days in a row",
                icon: "flame.fill",
                unlockedAt: Date()
            ))
        }
        
        achievements.append(contentsOf: newAchievements)
        saveAchievements()
    }
    
    private func calculateUpdateStreak(items: [WishlistItemEntity]) -> Int {
        let calendar = Calendar.current
        var dates = Set<Date>()
        
        for item in items {
            for update in item.priceUpdatesArray {
                let day = calendar.startOfDay(for: update.date)
                dates.insert(day)
            }
        }
        
        let sortedDates = dates.sorted(by: >)
        guard !sortedDates.isEmpty else { return 0 }
        
        var streak = 1
        var currentDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) || 
               calendar.isDate(date, equalTo: currentDate, toGranularity: .day) {
                if calendar.isDate(date, equalTo: currentDate, toGranularity: .day) {
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                    streak += 1
                }
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func saveAchievements() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }
    }
    
    func loadAchievements() {
        guard let data = UserDefaults.standard.data(forKey: "achievements"),
              let decoded = try? JSONDecoder().decode([Achievement].self, from: data) else {
            return
        }
        achievements = decoded
    }
}

// MARK: - Achievement Model

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let unlockedAt: Date
}
