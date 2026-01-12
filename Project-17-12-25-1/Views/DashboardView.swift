import SwiftUI
import Charts

enum SortOption: String, CaseIterable {
    case dateAdded = "Date Added"
    case name = "Name"
    case price = "Price"
    case dropPercentage = "Drop %"
    case savings = "Savings"
    
    var sortDescriptor: NSSortDescriptor {
        switch self {
        case .dateAdded:
            return NSSortDescriptor(key: "dateAdded", ascending: false)
        case .name:
            return NSSortDescriptor(key: "name", ascending: true)
        case .price:
            return NSSortDescriptor(key: "currentPrice", ascending: false)
        case .dropPercentage:
            return NSSortDescriptor(key: "originalPrice", ascending: true) // Will be sorted manually
        case .savings:
            return NSSortDescriptor(key: "originalPrice", ascending: false) // Will be sorted manually
        }
    }
}

enum FilterCategory: String, CaseIterable {
    case all = "All"
    case uncategorized = "Uncategorized"
}

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var themeManager: ThemeManager
    @FetchRequest(
        entity: WishlistItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateAdded", ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var allItems: FetchedResults<WishlistItemEntity>
    @State private var showAdd = false
    @State private var showGalleryPush = false
    @State private var searchText = ""
    @State private var selectedSort: SortOption = .dateAdded
    @State private var selectedCategory: String = "All"
    @State private var showFilters = false
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 10000
    @State private var filterByDate: Bool = false
    @State private var dateFrom: Date = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
    @State private var dateTo: Date = Date()
    
    private var categories: [String] {
        var cats = ["All"]
        let uniqueCategories = Set(allItems.compactMap { $0.category?.name })
        cats.append(contentsOf: uniqueCategories.sorted())
        cats.append("Uncategorized")
        return cats
    }
    
    private var items: [WishlistItemEntity] {
        var filtered = Array(allItems)
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.note?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.storeNote?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Category filter
        if selectedCategory != "All" {
            if selectedCategory == "Uncategorized" {
                filtered = filtered.filter { $0.category == nil }
            } else {
                filtered = filtered.filter { $0.category?.name == selectedCategory }
            }
        }
        
        // Price filter
        filtered = filtered.filter { item in
            item.currentPrice >= minPrice && item.currentPrice <= maxPrice
        }
        
        // Date filter
        if filterByDate {
            filtered = filtered.filter { item in
                item.dateAdded >= dateFrom && item.dateAdded <= dateTo
            }
        }
        
        // Sort
        switch selectedSort {
        case .dateAdded:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        case .name:
            filtered.sort { $0.name < $1.name }
        case .price:
            filtered.sort { $0.currentPrice > $1.currentPrice }
        case .dropPercentage:
            filtered.sort { $0.dropPercentage > $1.dropPercentage }
        case .savings:
            filtered.sort { $0.savings > $1.savings }
        }
        
        return filtered
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    searchAndFilters
                    header
                    ring
                    itemGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .background(themeManager.currentTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showFilters.toggle()
                        } label: {
                            Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        }
                        NavigationLink(destination: WishlistGalleryView()) {
                            Image(systemName: "square.grid.2x2.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                ItemFormView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showFilters) {
                FiltersView(
                    selectedCategory: $selectedCategory,
                    categories: categories,
                    selectedSort: $selectedSort,
                    minPrice: $minPrice,
                    maxPrice: $maxPrice,
                    filterByDate: $filterByDate,
                    dateFrom: $dateFrom,
                    dateTo: $dateTo
                )
            }
            .overlay(addButton, alignment: .bottomTrailing)
        }
    }
    
    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                TextField("Search items...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(themeManager.currentTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Quick filters
            if !searchText.isEmpty || selectedCategory != "All" || selectedSort != .dateAdded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if !searchText.isEmpty {
                            FilterChip(title: "Search: \(searchText)", action: { searchText = "" })
                        }
                        if selectedCategory != "All" {
                            FilterChip(title: "Category: \(selectedCategory)", action: { selectedCategory = "All" })
                        }
                        if selectedSort != .dateAdded {
                            FilterChip(title: "Sort: \(selectedSort.rawValue)", action: { selectedSort = .dateAdded })
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(items.count) \(items.count == 1 ? "item" : "items") on your wishlist")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(themeManager.currentTheme.textPrimary)
            if items.count != allItems.count {
                Text("Showing \(items.count) of \(allItems.count) items")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
            }
            
            HStack(spacing: 16) {
                statCard(title: "Estimated total value", value: estimatedValue.currency, icon: "dollarsign.circle.fill")
                statCard(title: "Total saved so far", value: totalSaved.currency, icon: "sparkles")
            }
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundStyle(themeManager.currentTheme.textSecondary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.currentTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard()
        .shadow(color: themeManager.currentTheme.textPrimary.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private var ring: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Карточка с четкой вертикальной структурой
            VStack(alignment: .leading, spacing: 24) {
                // Заголовок - четко отделен сверху
                Text("Average price drop")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                
                // Горизонтальная компоновка: прогресс-бар слева, текст справа
                HStack(alignment: .center, spacing: 20) {
                    // Прогресс-бар слева - фиксированный размер
                    ZStack {
                        // Фоновый круг
                        Circle()
                            .stroke(
                                themeManager.currentTheme.textPrimary.opacity(0.1),
                                lineWidth: 14
                            )
                        
                        // Прогресс круг
                        Circle()
                            .trim(from: 0, to: averageDrop)
                            .stroke(
                                themeManager.currentTheme.accent,
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: averageDrop)
                        
                        // Центральный текст
                        Text(averageDrop.percentString)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(themeManager.currentTheme.textPrimary)
                    }
                    .frame(width: 110, height: 110)

                    // Текстовое описание справа
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Celebrate drops")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(themeManager.currentTheme.textPrimary)
                        
                        Text("Shows the average discount across all active wishlist items. Update prices to watch this ring glow.")
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundStyle(themeManager.currentTheme.textSecondary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.currentTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: themeManager.currentTheme.textPrimary.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }

    private var itemGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !items.isEmpty {
                Text("Your wishlist")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                    .padding(.horizontal, 4)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                ForEach(items, id: \.id) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack {
                                if let data = item.photoData, let image = UIImage(data: data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    LinearGradient(
                                        colors: [
                                            .gray.opacity(0.4),
                                            themeManager.currentTheme.accent.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.name)
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                                    .lineLimit(2)
                                
                                Text("-\(item.dropPercentage.percentString) drop")
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .foregroundStyle(themeManager.currentTheme.textSecondary)
                                
                                if item.isArchived {
                                    Label("Archived", systemImage: "archivebox.fill")
                                        .font(.system(size: 11, weight: .medium, design: .default))
                                        .foregroundStyle(.orange)
                                        .padding(.top, 2)
                                }
                            }
                        }
                        .padding(12)
                        .glassBackground()
                        .shadow(color: themeManager.currentTheme.textPrimary.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
                
                if items.isEmpty {
                    emptyState
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            showAdd = true
        } label: {
            HStack {
                Image(systemName: "plus")
                Text("Add Item")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(themeManager.currentTheme.accent)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(radius: 12, y: 6)
            .padding()
        }
    }

    private var estimatedValue: Double {
        items.reduce(0) { $0 + $1.currentPrice }
    }

    private var totalSaved: Double {
        items.reduce(0) { $0 + $1.savings }
    }

    private var averageDrop: Double {
        let drops = items.map { $0.dropPercentage }
        guard !drops.isEmpty else { return 0 }
        return drops.reduce(0, +) / Double(drops.count)
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(themeManager.currentTheme.accent)
            Text("No items yet")
                .foregroundStyle(themeManager.currentTheme.textPrimary)
            Text("Add your first wish to start tracking drops.")
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassBackground()
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.textPrimary)
            Button {
                action()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(themeManager.currentTheme.card)
        .clipShape(Capsule())
    }
}

// MARK: - Filters View
struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: String
    let categories: [String]
    @Binding var selectedSort: SortOption
    @Binding var minPrice: Double
    @Binding var maxPrice: Double
    @Binding var filterByDate: Bool
    @Binding var dateFrom: Date
    @Binding var dateTo: Date
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Sort By") {
                    Picker("Sort", selection: $selectedSort) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                
                Section("Price Range") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Min: \(minPrice, specifier: "%.0f")")
                            Spacer()
                            Text("Max: \(maxPrice, specifier: "%.0f")")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Min Price")
                                Spacer()
                                TextField("0", value: $minPrice, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                            
                            HStack {
                                Text("Max Price")
                                Spacer()
                                TextField("10000", value: $maxPrice, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
                
                Section("Date Range") {
                    Toggle("Filter by date", isOn: $filterByDate)
                    
                    if filterByDate {
                        DatePicker("From", selection: $dateFrom, displayedComponents: .date)
                        DatePicker("To", selection: $dateTo, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
        .environmentObject(ThemeManager.shared)
}

