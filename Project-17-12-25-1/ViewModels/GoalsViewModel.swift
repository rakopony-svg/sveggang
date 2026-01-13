import Foundation
import CoreData

@MainActor
final class GoalsViewModel: ObservableObject {
    @Published var goals: [GoalEntity] = []
    @Published var achievements: [Achievement] = []
    @Published var showCreateGoal = false
    
    private let goalsService = GoalsService.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        goalsService.loadGoals()
        goalsService.loadAchievements()
        goals = goalsService.goals
        achievements = goalsService.achievements
    }
    
    func createGoal(
        title: String,
        type: GoalEntity.GoalType,
        targetValue: Double,
        period: GoalEntity.Period
    ) {
        goalsService.createGoal(
            title: title,
            type: type,
            targetValue: targetValue,
            period: period
        )
        loadData()
    }
    
    func deleteGoal(_ goal: GoalEntity) {
        goalsService.deleteGoal(goal)
        loadData()
    }
    
    func refreshGoals() {
        goalsService.updateGoalProgress()
        loadData()
    }
}
