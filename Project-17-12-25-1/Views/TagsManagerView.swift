import SwiftUI

struct TagsManagerView: View {
    @StateObject private var viewModel: TagsViewModel
    @State private var showCreateTag = false
    @State private var newTagName = ""
    
    init() {
        _viewModel = StateObject(wrappedValue: TagsViewModel(context: CoreDataStack.shared.context))
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tags) { tag in
                    HStack {
                        Circle()
                            .fill(Color(hex: tag.color))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: tag.iconName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white)
                            )
                        Text(tag.name)
                        Spacer()
                        Text("\(tag.itemCount)")
                            .font(.caption)
                            .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        viewModel.deleteTag(viewModel.tags[index])
                    }
                }
                
                Section {
                    Button {
                        showCreateTag = true
                    } label: {
                        Label("Create New Tag", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Tags")
            .sheet(isPresented: $showCreateTag) {
                CreateTagView(viewModel: viewModel)
            }
        }
    }
}

struct CreateTagView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TagsViewModel
    
    @State private var name = ""
    @State private var selectedColor = "#8EC5FC"
    @State private var selectedIcon = "tag.fill"
    
    let colors = ["#8EC5FC", "#E0C3FC", "#FFB6C1", "#FFD93D", "#6BCF7F", "#4ECDC4", "#FF6B6B"]
    let icons = ["tag.fill", "star.fill", "heart.fill", "bookmark.fill", "flag.fill", "pin.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Details") {
                    TextField("Tag name", text: $name)
                }
                
                Section("Color") {
                    HStack {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
                
                Section("Icon") {
                    HStack {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(selectedIcon == icon ? ThemeManager.shared.currentTheme.accent : ThemeManager.shared.currentTheme.textSecondary)
                                .frame(width: 40, height: 40)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                }
            }
            .navigationTitle("New Tag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createTag(name: name, color: selectedColor, iconName: selectedIcon)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TagsManagerView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}
