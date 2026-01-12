import SwiftUI
import PDFKit

struct PDFExporter {
    static func exportWishlist(items: [WishlistItemEntity]) -> URL? {
        let pageSize = CGSize(width: 612, height: 792) // US Letter
        let margin: CGFloat = 40
        let contentWidth = pageSize.width - (margin * 2)
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Wishlist-\(UUID().uuidString).pdf")
        
        do {
            try renderer.writePDF(to: url) { context in
                var pageNumber = 1
                var yOffset: CGFloat = margin
                
                // Заголовок
                let title = "My Wishlist"
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                    .foregroundColor: UIColor.label
                ]
                let titleSize = title.size(withAttributes: titleAttributes)
                context.beginPage()
                title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttributes)
                yOffset += titleSize.height + 20
                
                // Дата генерации
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .none
                let dateText = "Generated: \(dateFormatter.string(from: Date()))"
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                dateText.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: dateAttributes)
                yOffset += 30
                
                // Общая статистика
                let totalItems = items.count
                let totalValue = items.reduce(0) { $0 + $1.currentPrice }
                let totalSaved = items.reduce(0) { $0 + $1.savings }
                
                let statsText = "\(totalItems) items • Total value: \(totalValue.currency) • Saved: \(totalSaved.currency)"
                let statsAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.label
                ]
                statsText.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: statsAttributes)
                yOffset += 40
                
                // Товары
                for (index, item) in items.enumerated() {
                    // Проверка, нужна ли новая страница
                    if yOffset > pageSize.height - 300 {
                        context.beginPage()
                        pageNumber += 1
                        yOffset = margin
                    }
                    
                    // Фото товара (если есть)
                    if let photoData = item.photoData, let image = UIImage(data: photoData) {
                        let imageHeight: CGFloat = 120
                        let imageRect = CGRect(x: margin, y: yOffset, width: contentWidth, height: imageHeight)
                        image.draw(in: imageRect)
                        yOffset += imageHeight + 15
                    }
                    
                    // Название товара
                    let nameAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                        .foregroundColor: UIColor.label
                    ]
                    let nameSize = item.name.size(withAttributes: nameAttributes)
                    item.name.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: nameAttributes)
                    yOffset += nameSize.height + 10
                    
                    // Цены
                    let priceInfo = "Current: \(item.currentPrice.currency) • Original: \(item.originalPrice.currency)"
                    let priceAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                        .foregroundColor: UIColor.label
                    ]
                    priceInfo.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: priceAttributes)
                    yOffset += 20
                    
                    // Статистика
                    let itemStats = "Drop: \(item.dropPercentage.percentString) • Saved: \(item.savings.currency)"
                    let statsAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                        .foregroundColor: UIColor.secondaryLabel
                    ]
                    itemStats.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: statsAttributes)
                    yOffset += 20
                    
                    // Целевая цена (если установлена)
                    if item.desiredPrice > 0 {
                        let targetText = "Target price: \(item.desiredPrice.currency)"
                        let targetAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                            .foregroundColor: UIColor.secondaryLabel
                        ]
                        targetText.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: targetAttributes)
                        yOffset += 20
                    }
                    
                    // Категория (если есть)
                    if let category = item.category {
                        let categoryText = "Category: \(category.name)"
                        let categoryAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                            .foregroundColor: UIColor.tertiaryLabel
                        ]
                        categoryText.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: categoryAttributes)
                        yOffset += 20
                    }
                    
                    // Разделитель
                    if index < items.count - 1 {
                        yOffset += 10
                        let divider = UIBezierPath()
                        divider.move(to: CGPoint(x: margin, y: yOffset))
                        divider.addLine(to: CGPoint(x: pageSize.width - margin, y: yOffset))
                        UIColor.separator.setStroke()
                        divider.lineWidth = 0.5
                        divider.stroke()
                        yOffset += 20
                    }
                }
                
                // Footer на каждой странице
                let footerText = "Page \(pageNumber)"
                let footerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: UIColor.tertiaryLabel
                ]
                footerText.draw(at: CGPoint(x: margin, y: pageSize.height - 30), withAttributes: footerAttributes)
            }
            return url
        } catch {
            print("PDF export error: \(error)")
            return nil
        }
    }
}

