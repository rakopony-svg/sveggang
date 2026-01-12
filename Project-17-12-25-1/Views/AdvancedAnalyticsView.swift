import SwiftUI
import Charts

struct AdvancedAnalyticsView: View {
    @StateObject private var viewModel: AnalyticsViewModel
    @State private var showingCSVShare = false
    @State private var csvData: String = ""
    
    init() {
        _viewModel = StateObject(wrappedValue: AnalyticsViewModel(context: CoreDataStack.shared.context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    periodComparisonSection
                    yearlyReportSection
                    trackingEfficiencySection
                }
                .padding()
            }
            .background(ThemeManager.shared.currentTheme.background.ignoresSafeArea())
            .navigationTitle("Advanced Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        csvData = viewModel.exportCSV()
                        showingCSVShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingCSVShare) {
                ShareSheet(activityItems: [csvData])
            }
        }
    }
    
    private var periodComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Period Comparison")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if let comparison = viewModel.periodComparison {
                VStack(spacing: 16) {
                    comparisonRow(
                        title: "Total Savings",
                        current: comparison.currentPeriod.totalSavings.currency,
                        previous: comparison.previousPeriod.totalSavings.currency,
                        change: comparison.savingsChange,
                        changePercent: comparison.savingsChangePercent
                    )
                    
                    comparisonRow(
                        title: "Items Added",
                        current: "\(comparison.currentPeriod.totalItems)",
                        previous: "\(comparison.previousPeriod.totalItems)",
                        change: Double(comparison.itemsChange),
                        changePercent: comparison.previousPeriod.totalItems > 0 ? (Double(comparison.itemsChange) / Double(comparison.previousPeriod.totalItems)) * 100 : 0
                    )
                    
                    comparisonRow(
                        title: "Targets Reached",
                        current: "\(comparison.currentPeriod.targetsReached)",
                        previous: "\(comparison.previousPeriod.targetsReached)",
                        change: Double(comparison.currentPeriod.targetsReached - comparison.previousPeriod.targetsReached),
                        changePercent: comparison.previousPeriod.targetsReached > 0 ? (Double(comparison.currentPeriod.targetsReached - comparison.previousPeriod.targetsReached) / Double(comparison.previousPeriod.targetsReached)) * 100 : 0
                    )
                }
            } else {
                Text("No data available")
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            }
        }
        .themedCard()
    }
    
    private func comparisonRow(title: String, current: String, previous: String, change: Double, changePercent: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    Text(current)
                        .font(.headline)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Previous")
                        .font(.caption)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    Text(previous)
                        .font(.headline)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Change")
                        .font(.caption)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text("\(abs(changePercent), specifier: "%.1f")%")
                            .font(.headline)
                    }
                    .foregroundStyle(change >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(ThemeManager.shared.currentTheme.card.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var yearlyReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Yearly Report")
                    .font(.title2.bold())
                    .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                Spacer()
                Picker("Year", selection: $viewModel.selectedYear) {
                    ForEach(2020...2030, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedYear) { _ in
                    viewModel.loadData()
                }
            }
            
            if let report = viewModel.yearlyReport {
                VStack(spacing: 16) {
                    HStack {
                        statBox(title: "Total Savings", value: report.totalSavings.currency)
                        statBox(title: "Items Added", value: "\(report.totalItems)")
                        statBox(title: "Targets Reached", value: "\(report.totalTargetsReached)")
                    }
                    
                    if let bestMonth = report.bestMonth {
                        Text("Best Month: \(bestMonth.monthName) with \(bestMonth.totalSavings.currency) saved")
                            .font(.subheadline)
                            .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    }
                    
                    Chart(report.monthlyData, id: \.month) { data in
                        BarMark(
                            x: .value("Month", data.monthName),
                            y: .value("Savings", data.totalSavings)
                        )
                        .foregroundStyle(ThemeManager.shared.currentTheme.gradient)
                    }
                    .frame(height: 200)
                }
            }
        }
        .themedCard()
    }
    
    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(ThemeManager.shared.currentTheme.card.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var trackingEfficiencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracking Efficiency")
                .font(.title2.bold())
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            if let efficiency = viewModel.trackingEfficiency {
                VStack(spacing: 12) {
                    efficiencyRow(title: "Items with Updates", value: "\(efficiency.itemsWithUpdates) / \(efficiency.totalItems)")
                    efficiencyRow(title: "Target Reach Rate", value: "\(Int(efficiency.targetReachRate * 100))%")
                    efficiencyRow(title: "Avg Updates per Item", value: String(format: "%.1f", efficiency.averageUpdatesPerItem))
                    if efficiency.averageDaysToTarget > 0 {
                        efficiencyRow(title: "Avg Days to Target", value: String(format: "%.0f days", efficiency.averageDaysToTarget))
                    }
                }
            }
        }
        .themedCard()
    }
    
    private func efficiencyRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AdvancedAnalyticsView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}
