import SwiftUI

struct ExportReportsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: WishlistItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateAdded", ascending: false)]
    ) private var items: FetchedResults<WishlistItemEntity>
    @State private var exportedURL: URL?
    @State private var exportedImage: UIImage?
    @State private var showingShare = false
    @State private var showingItemPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Export & Reports")
                    .font(.largeTitle.bold())
                    .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)

                Text("Create beautiful exports to share your wishlist and price drops.")
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)

                VStack(spacing: 14) {
                    exportCard(
                        title: "Wishlist PDF",
                        subtitle: "Premium layout with photos, targets and savings.",
                        icon: "doc.richtext.fill",
                        action: exportPDF
                    )
                    exportCard(
                        title: "Share single item",
                        subtitle: "Generate a stylish share card for any item.",
                        icon: "square.and.arrow.up.fill",
                        action: { showingItemPicker = true }
                    )
                }
            }
            .padding()
        }
        .background(ThemeManager.shared.currentTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showingShare) {
            if let exportedURL {
                ShareSheet(activityItems: [exportedURL])
            } else if let exportedImage {
                ShareSheet(activityItems: [exportedImage])
            }
        }
        .sheet(isPresented: $showingItemPicker) {
            ItemPickerView { selectedItem in
                exportSingleItem(selectedItem)
            }
        }
    }

    private func exportCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(ThemeManager.shared.currentTheme.gradient)
                    Image(systemName: icon)
                        .foregroundStyle(Color.black)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                    Text(subtitle).font(.subheadline).foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            }
            .padding()
            .background(ThemeManager.shared.currentTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        }
    }

    private func exportPDF() {
        if let url = PDFExporter.exportWishlist(items: Array(items)) {
            exportedURL = url
            exportedImage = nil
            showingShare = true
        }
    }

    private func exportSingleItem(_ item: WishlistItemEntity) {
        if let image = ShareCardGenerator.generateShareCard(for: item) {
            exportedImage = image
            exportedURL = nil
            showingShare = true
        }
    }
}

// MARK: - Item Picker View

struct ItemPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        entity: WishlistItemEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "dateAdded", ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var items: FetchedResults<WishlistItemEntity>
    
    let onSelect: (WishlistItemEntity) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.id) { item in
                    Button {
                        onSelect(item)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            if let photoData = item.photoData, let image = UIImage(data: photoData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(ThemeManager.shared.currentTheme.accent.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "tag.fill")
                                            .foregroundStyle(ThemeManager.shared.currentTheme.accent)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                                Text(item.currentPrice.currency)
                                    .font(.subheadline)
                                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Item to Share")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportReportsView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}

