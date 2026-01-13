import SwiftUI

struct PriceUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var item: WishlistItemEntity
    @State private var newPrice: Double = 0
    @State private var showCelebrate = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Current: \(item.currentPrice.currency)")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter updated price")
                        .font(.subheadline)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    TextField("0", value: $newPrice, format: .number)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text("New savings: \((item.originalPrice - newPrice).currency)")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("History")
                        .font(.subheadline.bold())
                    if item.priceUpdatesArray.isEmpty {
                        Text("No history yet").foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    } else {
                        ForEach(item.priceUpdatesArray, id: \.id) { update in
                            HStack {
                                Text(update.date.formatted(date: .abbreviated, time: .omitted))
                                Spacer()
                                Text(update.price.currency)
                            }
                            .font(.caption)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Quick Price Update")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        applyUpdate()
                    }
                    .disabled(!isValidPrice)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                if showCelebrate {
                    ConfettiView()
                        .transition(.scale)
                        .frame(height: 120)
                }
            }
        }
        .onAppear { newPrice = item.currentPrice }
    }

    private func applyUpdate() {
        item.currentPrice = newPrice
        let update = PriceUpdateEntity(context: context)
        update.id = UUID()
        update.price = newPrice
        update.date = Date()
        update.item = item
        let mutable = item.mutableOrderedSetValue(forKey: "priceUpdates")
        mutable.add(update)
        try? context.save()
        withAnimation { showCelebrate = item.reachedTarget }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }

    private var isValidPrice: Bool {
        newPrice >= 0 && newPrice <= item.originalPrice
    }
}

struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<12) { i in
                Circle()
                    .fill(randomColor)
                    .frame(width: 10, height: 10)
                    .offset(x: animate ? CGFloat.random(in: -120...120) : 0,
                            y: animate ? CGFloat.random(in: -60...0) : 0)
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: 1.0).repeatCount(1, autoreverses: false).delay(Double(i) * 0.02), value: animate)
            }
        }
        .onAppear { animate = true }
    }

    private var randomColor: Color {
        [Color.pink, .yellow, .mint, .orange, .blue].randomElement() ?? .pink
    }
}

