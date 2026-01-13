import SwiftUI
import Charts

struct PriceHistoryChartView: View {
    @ObservedObject var item: WishlistItemEntity
    @State private var zoom: CGFloat = 1.0
    @State private var selection: PriceUpdateEntity?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(item.name) price trend")
                        .font(.headline)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                    Text("Track every update over time")
                        .font(.caption)
                        .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Latest").font(.caption).foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
                    Text((item.priceUpdatesArray.last?.price ?? item.currentPrice).currency)
                        .font(.subheadline.bold())
                        .foregroundStyle(ThemeManager.shared.currentTheme.textPrimary)
                }
            }

            Chart(item.priceUpdatesArray, id: \.id) { update in
                AreaMark(
                    x: .value("Date", update.date),
                    y: .value("Price", update.price)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Gradient(colors: [ThemeManager.shared.currentTheme.accent.opacity(0.35), .clear]))

                LineMark(
                    x: .value("Date", update.date),
                    y: .value("Price", update.price)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(ThemeManager.shared.currentTheme.accent)

                PointMark(
                    x: .value("Date", update.date),
                    y: .value("Price", update.price)
                )
                .symbolSize(zoom * 20)
            }
            .chartXScale(domain: zoomedDomain ?? fallbackDomain)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 320)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0).onEnded { value in
                                let point = value.location
                                if let hit = nearestUpdate(at: point, proxy: proxy, geo: geo) {
                                    selection = hit
                                }
                            }
                        )
                }
            }
            .gesture(MagnificationGesture().onChanged { value in
                zoom = max(0.5, min(3.0, value))
            })

            if let selection {
                HStack {
                    Text(selection.date.formatted(date: .abbreviated, time: .omitted))
                    Spacer()
                    Text(selection.price.currency)
                }
                .font(.caption)
                .foregroundStyle(ThemeManager.shared.currentTheme.textSecondary)
            }
        }
        .padding()
        .background(ThemeManager.shared.currentTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var zoomedDomain: ClosedRange<Date>? {
        let dates = item.priceUpdatesArray.map { $0.date }.sorted()
        guard let first = dates.first, let last = dates.last else { return nil }
        let interval = max(1, last.timeIntervalSince(first) / Double(zoom))
        return first...(first.addingTimeInterval(interval))
    }

    private var fallbackDomain: ClosedRange<Date> {
        let now = Date()
        return now.addingTimeInterval(-86400)...now
    }

    private func nearestUpdate(at point: CGPoint, proxy: ChartProxy, geo: GeometryProxy) -> PriceUpdateEntity? {
        let plotFrame = geo[proxy.plotAreaFrame]
        let relativeX = point.x - plotFrame.origin.x
        guard relativeX >= 0, relativeX <= plotFrame.size.width else { return nil }
        guard let date: Date = proxy.value(atX: relativeX + plotFrame.origin.x) else { return nil }
        let updates = item.priceUpdatesArray
        return updates.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
}

#Preview {
    let context = CoreDataStack.shared.context
    let item = WishlistItemEntity(context: context)
    item.id = UUID()
    item.name = "Preview"
    item.originalPrice = 200
    item.currentPrice = 150
    item.desiredPrice = 120
    item.dateAdded = .now
    for offset in 0..<5 {
        let update = PriceUpdateEntity(context: context)
        update.id = UUID()
        update.price = Double(200 - offset * 10)
        update.date = Calendar.current.date(byAdding: .day, value: offset * 3, to: Date()) ?? Date()
        update.item = item
    }
    return PriceHistoryChartView(item: item)
        .environment(\.managedObjectContext, context)
}

