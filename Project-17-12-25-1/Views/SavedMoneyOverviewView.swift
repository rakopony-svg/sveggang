import SwiftUI
import Charts

struct SavedMoneyOverviewView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel: SavingsOverviewViewModel

    init() {
        _viewModel = StateObject(wrappedValue: SavingsOverviewViewModel(context: CoreDataStack.shared.context))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Saved Money Overview")
                    .font(.largeTitle.bold())
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                if viewModel.currentPeriodSavings.isEmpty && viewModel.categoryBreakdown.isEmpty {
                    emptyState
                } else {
                    summaryHeader
                    monthlyChart
                    categoryBreakdown
                    highlights
                }
            }
            .padding()
        }
        .background(themeManager.currentTheme.background.ignoresSafeArea())
        .onAppear { viewModel.load() }
    }

    private var summaryHeader: some View {
        HStack(spacing: 12) {
            statCard(title: "Total saved", value: totalSaved.currency, icon: "sparkles")
            statCard(title: "Best month", value: bestMonthValue.currency, icon: "calendar")
        }
    }

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(periodTitle)
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                Spacer()
                Picker("Period", selection: $viewModel.selectedTimePeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.menu)
            }
            Chart {
                ForEach(viewModel.currentPeriodSavings, id: \.0) { entry in
                    BarMark(
                        x: .value(periodXLabel, entry.0, unit: periodUnit),
                        y: .value("Saved", entry.1)
                    )
                    .foregroundStyle(themeManager.currentTheme.accent)
                }
                ForEach(viewModel.currentPeriodSavings, id: \.0) { entry in
                    LineMark(
                        x: .value(periodXLabel, entry.0, unit: periodUnit),
                        y: .value("Cumulative", cumulative(for: entry.0))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(themeManager.currentTheme.accent)
                    AreaMark(
                        x: .value(periodXLabel, entry.0, unit: periodUnit),
                        y: .value("Cumulative", cumulative(for: entry.0))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(themeManager.currentTheme.accent.opacity(0.2))
                }
            }
            .frame(height: 240)
        }
        .themedCard()
    }
    
    private var periodTitle: String {
        switch viewModel.selectedTimePeriod {
        case .daily: return "By day"
        case .weekly: return "By week"
        case .monthly: return "By month"
        case .yearly: return "By year"
        }
    }
    
    private var periodXLabel: String {
        switch viewModel.selectedTimePeriod {
        case .daily: return "Day"
        case .weekly: return "Week"
        case .monthly: return "Month"
        case .yearly: return "Year"
        }
    }
    
    private var periodUnit: Calendar.Component {
        switch viewModel.selectedTimePeriod {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By category")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.textPrimary)
            ForEach(viewModel.categoryBreakdown, id: \.0) { entry in
                HStack {
                    Text(entry.0)
                    Spacer()
                    Text(entry.1.currency)
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
        .themedCard()
    }

    private var highlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)
                .foregroundStyle(themeManager.currentTheme.textPrimary)
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Biggest saving: \(viewModel.highlights.biggestSaving)", systemImage: "sparkles")
                    Label("Most improved: \(viewModel.highlights.mostImproved)", systemImage: "chart.line.uptrend.xyaxis")
                }
                Spacer()
            }
        }
        .themedCard()
        .frame(maxWidth: .infinity)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(themeManager.currentTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(themeManager.currentTheme.textSecondary)
                Text(value).font(.headline).foregroundStyle(themeManager.currentTheme.textPrimary)
            }
            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(themeManager.currentTheme.accent)
            Text("No savings yet")
                .font(.title3.bold())
                .foregroundStyle(themeManager.currentTheme.textPrimary)
            Text("Add items and log price updates to see savings visualized here.")
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.background.ignoresSafeArea())
    }

    private var totalSaved: Double {
        viewModel.currentPeriodSavings.reduce(0) { $0 + $1.1 }
    }

    private var bestMonthValue: Double {
        viewModel.currentPeriodSavings.map(\.1).max() ?? 0
    }

    private func cumulative(for date: Date) -> Double {
        viewModel.currentPeriodSavings.filter { $0.0 <= date }.reduce(0) { $0 + $1.1 }
    }
}

#Preview {
    SavedMoneyOverviewView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
        .environmentObject(ThemeManager.shared)
}

