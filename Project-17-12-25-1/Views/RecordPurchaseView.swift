import SwiftUI

struct RecordPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var item: WishlistItemEntity
    @State private var purchasePrice: Double = 0
    @State private var notes: String = ""
    
    private let purchaseService = PurchaseHistoryService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Purchase Details") {
                    HStack {
                        Text("Purchase Price")
                        Spacer()
                        TextField("0", value: $purchasePrice, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                
                Section("Comparison") {
                    if purchasePrice > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Original Price:")
                                Spacer()
                                Text(item.originalPrice.currency)
                            }
                            HStack {
                                Text("Minimum Price Seen:")
                                Spacer()
                                Text(item.minimumPriceSeen.currency)
                            }
                            HStack {
                                Text("You'll save:")
                                Spacer()
                                Text((item.originalPrice - purchasePrice).currency)
                                    .foregroundStyle(.green)
                            }
                            if purchasePrice > item.minimumPriceSeen {
                                HStack {
                                    Text("Could have saved more:")
                                    Spacer()
                                    Text((purchasePrice - item.minimumPriceSeen).currency)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Record Purchase")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        purchaseService.recordPurchase(
                            for: item,
                            purchasePrice: purchasePrice,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                    .disabled(purchasePrice <= 0)
                }
            }
        }
        .onAppear {
            purchasePrice = item.currentPrice
        }
    }
}

#Preview {
    let context = CoreDataStack.shared.context
    let item = WishlistItemEntity(context: context)
    item.id = UUID()
    item.name = "Sample Item"
    item.originalPrice = 250
    item.currentPrice = 180
    item.desiredPrice = 150
    item.dateAdded = .now
    return RecordPurchaseView(item: item)
        .environment(\.managedObjectContext, context)
}
