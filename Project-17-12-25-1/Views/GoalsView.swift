import SwiftUI
import Charts

struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    achievementsSection
                    activeGoalsSection
                    completedGoalsSection
                }
                .padding()
            }
            .background(ThemeManager.shared.currentTheme.background.ignoresSafeArea())
            .navigationTitle("Goals & Achievements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showCreateGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateGoal) {
                CreateGoalView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.refreshGoals()
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if viewModel.achievements.isEmpty {
                Text("No achievements yet. Keep tracking to unlock!")
                    .font(.subheadline)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(viewModel.achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
            }
        }
        .themedCard()
    }
    
    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Goals")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            let activeGoals = viewModel.goals.filter { $0.isActive }
            
            if activeGoals.isEmpty {
                Text("No active goals. Create one to get started!")
                    .font(.subheadline)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    .padding()
            } else {
                ForEach(activeGoals) { goal in
                    GoalCard(goal: goal, viewModel: viewModel)
                }
            }
        }
        .themedCard()
    }
    
    private var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed Goals")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            let completedGoals = viewModel.goals.filter { $0.isCompleted }
            
            if completedGoals.isEmpty {
                EmptyView()
            } else {
                ForEach(completedGoals.prefix(5)) { goal in
                    GoalCard(goal: goal, viewModel: viewModel)
                }
            }
        }
        .themedCard()
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(ThemeManager.shared.currentTheme.accent)
            
            Text(achievement.title)
                .font(.headline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ThemeManager.shared.currentTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GoalCard: View {
    let goal: GoalEntity
    let viewModel: GoalsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                Spacer()
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            ProgressView(value: goal.progress) {
                HStack {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    Spacer()
                    Text("\(goal.currentValue, specifier: "%.0f") / \(goal.targetValue, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                }
            }
            .progressViewStyle(.linear)
            
            HStack {
                Label(GoalEntity.Period(rawValue: goal.period)?.displayName ?? "", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                Spacer()
                if goal.isActive {
                    Text("\(goal.daysRemaining) days left")
                        .font(.caption)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                }
            }
            
            if !goal.isCompleted {
                Button(role: .destructive) {
                    viewModel.deleteGoal(goal)
                } label: {
                    Text("Delete")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(ThemeManager.shared.currentTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GoalsViewModel
    
    @State private var title = ""
    @State private var selectedType: GoalEntity.GoalType = .savings
    @State private var targetValue: Double = 100
    @State private var selectedPeriod: GoalEntity.Period = .monthly
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal title", text: $title)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(GoalEntity.GoalType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(GoalEntity.Period.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    
                    HStack {
                        Text("Target Value")
                        Spacer()
                        TextField("0", value: $targetValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createGoal(
                            title: title,
                            type: selectedType,
                            targetValue: targetValue,
                            period: selectedPeriod
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    GoalsView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}
