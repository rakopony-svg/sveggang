import SwiftUI

struct WishlistGalleryView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var themeManager: ThemeManager
    @FetchRequest(
        entity: WishlistItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateAdded", ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var items: FetchedResults<WishlistItemEntity>

    @State private var selectedCategory: String = "All"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Wishlist Gallery")
                        .font(.largeTitle.bold())
                        .foregroundStyle(themeManager.currentTheme.textPrimary)
                    Spacer()
                    Menu {
                        Button("All") { selectedCategory = "All" }
                        ForEach(Array(Set(items.compactMap { $0.category?.name })), id: \.self) { name in
                            Button(name) { selectedCategory = name }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                if filteredItems.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                        ForEach(filteredItems, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack {
                                    if let data = item.photoData, let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        themeManager.currentTheme.gradient
                                    }
                                }
                            }
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .overlay(alignment: .bottomLeading) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                                    Text("-\(item.dropPercentage.percentString)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.95))
                                        .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .black.opacity(item.photoData == nil ? 0.75 : 0.35)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var filteredItems: [WishlistItemEntity] {
        if selectedCategory == "All" { return Array(items) }
        return items.filter { $0.category?.name == selectedCategory }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(themeManager.currentTheme.accent)
            Text("Gallery is empty")
                .font(.title3.bold())
                .foregroundStyle(themeManager.currentTheme.textPrimary)
            Text("Add items with photos to see them showcased here.")
                .font(.subheadline)
                .foregroundStyle(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.background)
    }
}

#Preview {
    WishlistGalleryView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
        .environmentObject(ThemeManager.shared)
}

