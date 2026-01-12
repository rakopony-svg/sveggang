import Foundation
import CoreData

enum TimePeriod: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

@MainActor
final class SavingsOverviewViewModel: ObservableObject {
    @Published var monthlySavings: [(Date, Double)] = []
    @Published var weeklySavings: [(Date, Double)] = []
    @Published var dailySavings: [(Date, Double)] = []
    @Published var yearlySavings: [(Date, Double)] = []
    @Published var categoryBreakdown: [(String, Double)] = []
    @Published var highlights: (biggestSaving: String, mostImproved: String) = ("–", "–")
    @Published var selectedTimePeriod: TimePeriod = .monthly

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
            monthlySavings = aggregateMonthly(items: items)
            weeklySavings = aggregateWeekly(items: items)
            dailySavings = aggregateDaily(items: items)
            yearlySavings = aggregateYearly(items: items)
            categoryBreakdown = aggregateCategory(items: items)
            highlights = computeHighlights(items: items)
        } catch {
            print("Savings fetch error: \(error)")
        }
    }
    
    var currentPeriodSavings: [(Date, Double)] {
        switch selectedTimePeriod {
        case .daily:
            return dailySavings
        case .weekly:
            return weeklySavings
        case .monthly:
            return monthlySavings
        case .yearly:
            return yearlySavings
        }
    }

    private func aggregateDaily(items: [WishlistItemEntity]) -> [(Date, Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.dateAdded)
        }
        let mapped = grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.savings }) }
        return mapped.sorted { $0.0 < $1.0 }
    }
    
    private func aggregateWeekly(items: [WishlistItemEntity]) -> [(Date, Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: item.dateAdded)
            return calendar.date(from: components) ?? item.dateAdded
        }
        let mapped = grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.savings }) }
        return mapped.sorted { $0.0 < $1.0 }
    }

    private func aggregateMonthly(items: [WishlistItemEntity]) -> [(Date, Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
            calendar.date(from: calendar.dateComponents([.year, .month], from: item.dateAdded)) ?? .now
        }
        let mapped = grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.savings }) }
        return mapped.sorted { $0.0 < $1.0 }
    }
    
    private func aggregateYearly(items: [WishlistItemEntity]) -> [(Date, Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
            calendar.date(from: calendar.dateComponents([.year], from: item.dateAdded)) ?? .now
        }
        let mapped = grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.savings }) }
        return mapped.sorted { $0.0 < $1.0 }
    }

    private func aggregateCategory(items: [WishlistItemEntity]) -> [(String, Double)] {
        let grouped = Dictionary(grouping: items) { item in
            item.category?.name ?? "Uncategorized"
        }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.savings }) }
            .sorted { $0.1 > $1.1 }
    }

    private func computeHighlights(items: [WishlistItemEntity]) -> (String, String) {
        let biggest = items.max { $0.savings < $1.savings }?.name ?? "–"
        let improved = items.max { $0.dropPercentage < $1.dropPercentage }?.name ?? "–"
        return (biggest, improved)
    }
}

