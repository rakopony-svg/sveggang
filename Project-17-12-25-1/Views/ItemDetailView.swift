import SwiftUI
import Charts

struct ItemDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var item: WishlistItemEntity
    @State private var showUpdate = false
    @State private var showEdit = false
    @State private var showRecordPurchase = false
    @State private var purchasePrice: Double = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                tagsSection
                priceSummary
                pricePrediction
                historyChart
                purchaseHistorySection
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle(item.name)
        .toolbar {
            Button("Edit") { showEdit = true }
        }
        .sheet(isPresented: $showUpdate) {
            PriceUpdateView(item: item)
        }
        .sheet(isPresented: $showEdit) {
            ItemFormView(item: item)
        }
        .sheet(isPresented: $showRecordPurchase) {
            RecordPurchaseView(item: item)
        }
        .background(ThemeManager.shared.currentTheme.background.ignoresSafeArea())
    }

    private var header: some View {
        ZStack(alignment: .bottomTrailing) {
            if let data = item.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ThemeManager.shared.currentTheme.gradient
                    .overlay(
                        Image(systemName: "tag.fill")
                            .font(.system(size: 60, weight: .black))
                            .foregroundStyle(.white.opacity(0.6))
                    )
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Text("-\(item.dropPercentage.percentString)")
                .font(.headline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(16)
        }
    }

    private var priceSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price journey")
                .font(.headline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            HStack(spacing: 12) {
                pill(title: "Original", value: item.originalPrice.currency)
                pill(title: "Current", value: item.currentPrice.currency)
                pill(title: "Target", value: item.desiredPrice.currency)
            }
            let progress = progressToTarget
            ProgressView(value: progress) {
                Text("Progress to target")
            } currentValueLabel: {
                Text((progress * 100).rounded().formatted() + "%")
            }
            .progressViewStyle(.linear)
            Text(progressDescription)
                .font(.caption)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .glassBackground()
    }

    private func pill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var pricePrediction: some View {
        Group {
            if let prediction = PricePredictionService.shared.predictPrice(for: item) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "crystal.ball.fill")
                            .foregroundStyle(ThemeManager.shared.currentTheme.accent)
                        Text("Price Prediction")
                            .font(.headline)
                            .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Predicted price in 7 days:")
                                .font(.subheadline)
                                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                            Spacer()
                            Text(prediction.predictedPrice.currency)
                                .font(.headline.bold())
                                .foregroundStyle(ThemeManager.shared.currentTheme.accent)
                        }
                        
                        HStack {
                            Text("Drop probability:")
                                .font(.subheadline)
                                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                            Spacer()
                            Text("\(Int(prediction.dropProbability * 100))%")
                                .font(.subheadline.bold())
                                .foregroundStyle(prediction.dropProbability > 0.5 ? .green : .orange)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text(prediction.recommendation)
                            .font(.caption)
                            .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                    }
                }
                .padding(20)
                .background(ThemeManager.shared.currentTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }
    
    private var historyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price history")
                .font(.headline)
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            PriceHistoryChartView(item: item)
                .frame(height: 260)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .glassBackground()
    }

    private var tagsSection: some View {
        Group {
            if !item.tagsArray.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tags")
                        .font(.headline)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(item.tagsArray, id: \.id) { tag in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: tag.color))
                                        .frame(width: 12, height: 12)
                                    Text(tag.name)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ThemeManager.shared.currentTheme.card)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .glassBackground()
            }
        }
    }
    
    private var purchaseHistorySection: some View {
        Group {
            if let purchase = item.purchaseHistory {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Purchase History")
                        .font(.headline)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Purchased for:")
                                .font(.subheadline)
                                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                            Spacer()
                            Text(purchase.purchasePrice.currency)
                                .font(.headline)
                                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                        }
                        
                        HStack {
                            Text("Saved:")
                                .font(.subheadline)
                                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                            Spacer()
                            Text(purchase.totalSavings.currency)
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                        
                        if purchase.couldHaveSavedMore {
                            HStack {
                                Text("Could have saved more:")
                                    .font(.subheadline)
                                    .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                Text(purchase.missedSavings.currency)
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        Text(purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .glassBackground()
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showUpdate = true
            } label: {
                label(icon: "arrow.down.circle.fill", title: "Update Price")
            }
            NavigationLink {
                PriceHistoryChartView(item: item)
            } label: {
                label(icon: "chart.line.uptrend.xyaxis", title: "Price History Chart")
            }
            if !item.isBought {
                Button {
                    showRecordPurchase = true
                } label: {
                    label(icon: "cart.fill", title: "Record Purchase")
                }
            }
            Button {
                item.isBought.toggle()
                try? context.save()
            } label: {
                label(icon: "checkmark.seal.fill", title: item.isBought ? "Marked Bought" : "Mark as Bought")
            }
            Button(role: .destructive) {
                item.isArchived.toggle()
                try? context.save()
            } label: {
                label(icon: "archivebox.fill", title: item.isArchived ? "Unarchive" : "Archive")
            }
        }
    }

    private func label(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
            Text(title)
                .font(.body)
                .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var progressToTarget: Double {
        let totalDrop = max(1, item.originalPrice - item.desiredPrice)
        let achieved = item.originalPrice - item.currentPrice
        return min(1, max(0, achieved / totalDrop))
    }

    private var progressDescription: String {
        if progressToTarget >= 1 {
            return "You reached your target price. Celebrate the win!"
        } else {
            let remaining = max(0, item.currentPrice - item.desiredPrice)
            return "You're \(remaining.currency) away from your target. Keep tracking."
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
    return NavigationStack {
        ItemDetailView(item: item)
    }.environment(\.managedObjectContext, context)
}

