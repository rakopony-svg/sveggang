import SwiftUI

struct CategoriesManagerView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: CategoriesViewModel
    @State private var newName = ""

    init() {
        _viewModel = StateObject(wrappedValue: CategoriesViewModel(context: CoreDataStack.shared.context))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.categories) { category in
                    HStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: category.gradientTopColor), Color(hex: category.gradientBottomColor)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                            .overlay(Image(systemName: category.iconName).foregroundStyle(.white))
                        Text(category.name)
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { viewModel.categories[$0] }.forEach(viewModel.delete)
                }
                .onMove(perform: viewModel.move)

                Section("Add Category") {
                    TextField("Name", text: $newName)
                    Button("Add") {
                        viewModel.add(name: newName, icon: "star.fill", top: "#8EC5FC", bottom: "#E0C3FC")
                        newName = ""
                    }
                    .disabled(newName.isEmpty)
                }
            }
            .navigationTitle("Categories")
            .toolbar { EditButton() }
        }
    }
}

#Preview {
    CategoriesManagerView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}

