import SwiftUI

struct WishlistMapView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: WishlistItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateAdded", ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var items: FetchedResults<WishlistItemEntity>
    
    @State private var selectedGrouping: GroupingType = .category
    @State private var selectedItem: WishlistItemEntity?
    
    enum GroupingType: String, CaseIterable {
        case category = "Category"
        case priceRange = "Price Range"
        case dropPercentage = "Drop %"
        case targetStatus = "Target Status"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    groupingSelector
                    mapVisualization
                }
                .padding()
            }
            .background(ThemeManager.shared.currentTheme.background.ignoresSafeArea())
            .navigationTitle("Wishlist Map")
            .sheet(item: $selectedItem) { item in
                NavigationStack {
                    ItemDetailView(item: item)
                }
            }
        }
    }
    
    private var groupingSelector: some View {
        Picker("Group by", selection: $selectedGrouping) {
            ForEach(GroupingType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var mapVisualization: some View {
        let grouped = groupItems()
        
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(grouped.keys.sorted()), id: \.self) { key in
                if let groupItems = grouped[key] {
                    GroupSection(
                        title: key,
                        items: groupItems,
                        onItemTap: { item in
                            selectedItem = item
                        }
                    )
                }
            }
        }
    }
    
    private func groupItems() -> [String: [WishlistItemEntity]] {
        switch selectedGrouping {
        case .category:
            return Dictionary(grouping: Array(items)) { item in
                item.category?.name ?? "Uncategorized"
            }
        case .priceRange:
            return Dictionary(grouping: Array(items)) { item in
                let price = item.currentPrice
                if price < 50 { return "$0-$50" }
                if price < 100 { return "$50-$100" }
                if price < 500 { return "$100-$500" }
                return "$500+"
            }
        case .dropPercentage:
            return Dictionary(grouping: Array(items)) { item in
                let drop = item.dropPercentage
                if drop < 0.1 { return "0-10% drop" }
                if drop < 0.25 { return "10-25% drop" }
                if drop < 0.5 { return "25-50% drop" }
                return "50%+ drop"
            }
        case .targetStatus:
            return Dictionary(grouping: Array(items)) { item in
                if item.reachedTarget { return "Target Reached" }
                if item.desiredPrice > 0 { return "Has Target" }
                return "No Target"
            }
        }
    }
}

struct GroupSection: View {
    let title: String
    let items: [WishlistItemEntity]
    let onItemTap: (WishlistItemEntity) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items, id: \.id) { item in
                        MapItemCard(item: item) {
                            onItemTap(item)
                        }
                    }
                }
            }
        }
        .padding()
        .background(ThemeManager.shared.currentTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MapItemCard: View {
    let item: WishlistItemEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    if let data = item.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ThemeManager.shared.currentTheme.gradient
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                Text(item.name)
                    .font(.caption)
                    .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                    .lineLimit(2)
                
                Text(item.currentPrice.currency)
                    .font(.caption.bold())
                    .foregroundStyle(ThemeManager.shared.currentTheme.accent)
            }
            .frame(width: 120)
        }
    }
}

#Preview {
    WishlistMapView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}
