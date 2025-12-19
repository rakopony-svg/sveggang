import Foundation
import CoreData

@objc(GoalEntity)
class GoalEntity: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var type: String // "savings", "updates", "targets"
    @NSManaged var targetValue: Double
    @NSManaged var currentValue: Double
    @NSManaged var period: String // "daily", "weekly", "monthly", "yearly"
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date
    @NSManaged var isCompleted: Bool
    @NSManaged var createdAt: Date
}

extension GoalEntity {
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, max(0.0, currentValue / targetValue))
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate && !isCompleted
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }
    
    enum GoalType: String, CaseIterable {
        case savings = "savings"
        case updates = "updates"
        case targets = "targets"
        
        var displayName: String {
            switch self {
            case .savings: return "Savings Goal"
            case .updates: return "Updates Goal"
            case .targets: return "Targets Reached"
            }
        }
    }
    
    enum Period: String, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
    }
}
