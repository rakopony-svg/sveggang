import SwiftUI

struct ItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: ItemFormViewModel
    @StateObject private var tagsViewModel = TagsViewModel(context: CoreDataStack.shared.context)
    @State private var showPhotoPicker = false
    @State private var selectedTags: Set<UUID> = []
    @FetchRequest(
        entity: CategoryEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)]
    ) private var categories: FetchedResults<CategoryEntity>
    @FetchRequest(
        entity: TagEntity.entity(),
        sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
    ) private var tags: FetchedResults<TagEntity>

    init(item: WishlistItemEntity? = nil) {
        let ctx = CoreDataStack.shared.context
        _viewModel = StateObject(wrappedValue: ItemFormViewModel(context: ctx, item: item))
        if let item = item {
            _selectedTags = State(initialValue: Set(item.tagsArray.map { $0.id }))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Essentials") {
                    TextField("Item name", text: $viewModel.name)
                    HStack {
                        priceField(title: "Original", value: $viewModel.originalPrice)
                        priceField(title: "Current", value: $viewModel.currentPrice)
                        priceField(title: "Desired", value: $viewModel.desiredPrice)
                    }
                    DatePicker("Date added", selection: $viewModel.dateAdded, displayedComponents: .date)
                }

                Section("Photo") {
                    Button {
                        showPhotoPicker.toggle()
                    } label: {
                        Label(viewModel.photoData == nil ? "Add photo" : "Change photo", systemImage: "photo.on.rectangle")
                    }
                    if let data = viewModel.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }

                Section("Notes") {
                    Picker("Category", selection: $viewModel.category) {
                        Text("Uncategorized").tag(CategoryEntity?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(CategoryEntity?.some(category))
                        }
                    }
                    TextField("Store / website", text: $viewModel.storeNote)
                    TextField("Personal note", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                
                Section("Tags") {
                    if tags.isEmpty {
                        Text("No tags yet. Create tags in Settings.")
                            .font(.caption)
                            .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    } else {
                        ForEach(tags) { tag in
                            Toggle(isOn: Binding(
                                get: { selectedTags.contains(tag.id) },
                                set: { isOn in
                                    if isOn {
                                        selectedTags.insert(tag.id)
                                    } else {
                                        selectedTags.remove(tag.id)
                                    }
                                }
                            )) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: tag.color))
                                        .frame(width: 16, height: 16)
                                    Text(tag.name)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Item" : "Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        // Сохраняем теги
                        if let item = viewModel.item {
                            let allTags = tags.filter { selectedTags.contains($0.id) }
                            let currentTags = item.tagsArray
                            
                            // Удаляем теги, которые не выбраны
                            for tag in currentTags where !selectedTags.contains(tag.id) {
                                tagsViewModel.removeTag(tag, from: item)
                            }
                            
                            // Добавляем новые теги
                            for tag in allTags where !currentTags.contains(where: { $0.id == tag.id }) {
                                tagsViewModel.addTag(tag, to: item)
                            }
                        }
                        dismiss()
                    }
                    .disabled(viewModel.name.isEmpty || viewModel.originalPrice <= 0 || viewModel.desiredPrice <= 0)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(data: $viewModel.photoData)
            }
        }
    }

    private func priceField(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption)
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var data: Data?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.data = image.jpegData(compressionQuality: 0.8)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ItemFormView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}

