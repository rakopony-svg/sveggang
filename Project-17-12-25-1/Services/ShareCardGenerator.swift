import SwiftUI
import UIKit

/// Генератор красивых карточек для шаринга товаров
struct ShareCardGenerator {
    
    /// Создать изображение карточки для шаринга товара
    static func generateShareCard(for item: WishlistItemEntity) -> UIImage? {
        let size = CGSize(width: 1200, height: 1600) // Оптимальный размер для шаринга
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Фон с градиентом
            drawGradientBackground(in: cgContext, size: size, theme: ThemeManager.shared.currentTheme)
            
            // Основной контент
            var yOffset: CGFloat = 120
            
            // Фото товара (если есть)
            if let photoData = item.photoData, let image = UIImage(data: photoData) {
                let imageRect = CGRect(x: 100, y: yOffset, width: size.width - 200, height: 600)
                image.draw(in: imageRect)
                yOffset += 650
            } else {
                // Placeholder с иконкой
                let placeholderRect = CGRect(x: 100, y: yOffset, width: size.width - 200, height: 400)
                drawPlaceholder(in: cgContext, rect: placeholderRect, theme: ThemeManager.shared.currentTheme)
                yOffset += 450
            }
            
            // Название товара
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor(ThemeManager.shared.currentTheme.textPrimary)
            ]
            let nameRect = CGRect(x: 100, y: yOffset, width: size.width - 200, height: 80)
            item.name.draw(in: nameRect, withAttributes: nameAttributes)
            yOffset += 100
            
            // Цены
            yOffset += 40
            drawPriceInfo(in: cgContext, item: item, yOffset: &yOffset, size: size)
            
            // Статистика
            yOffset += 60
            drawStatistics(in: cgContext, item: item, yOffset: &yOffset, size: size)
            
            // Footer с брендингом
            drawFooter(in: cgContext, size: size)
        }
    }
    
    // MARK: - Private Drawing Methods
    
    private static func drawGradientBackground(in context: CGContext, size: CGSize, theme: AppTheme) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let uiColors = [
            UIColor(theme.background),
            UIColor(theme.card)
        ]
        let colors = uiColors.map { $0.cgColor }
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]) else {
            return
        }
        
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
    }
    
    private static func drawPlaceholder(in context: CGContext, rect: CGRect, theme: AppTheme) {
        // Рисуем градиентный фон для placeholder
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let uiColors = [
            UIColor(theme.accent).withAlphaComponent(0.3),
            UIColor(theme.accent).withAlphaComponent(0.1)
        ]
        let colors = uiColors.map { $0.cgColor }
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]) else {
            return
        }
        
        context.saveGState()
        context.addRect(rect)
        context.clip()
        context.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
        context.restoreGState()
        
        // Иконка
        let iconSize: CGFloat = 120
        let iconRect = CGRect(
            x: rect.midX - iconSize / 2,
            y: rect.midY - iconSize / 2,
            width: iconSize,
            height: iconSize
        )
        
        // Рисуем простую иконку (можно использовать SF Symbols через текст)
        let iconAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: iconSize * 0.6, weight: .bold),
            .foregroundColor: UIColor(theme.accent)
        ]
        "🏷️".draw(in: iconRect, withAttributes: iconAttributes)
    }
    
    private static func drawPriceInfo(in context: CGContext, item: WishlistItemEntity, yOffset: inout CGFloat, size: CGSize) {
        let priceAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 72, weight: .black),
            .foregroundColor: UIColor(ThemeManager.shared.currentTheme.accent)
        ]
        
        let currentPriceText = item.currentPrice.currency
        let priceSize = currentPriceText.size(withAttributes: priceAttributes)
        let priceRect = CGRect(x: 100, y: yOffset, width: size.width - 200, height: priceSize.height)
        currentPriceText.draw(in: priceRect, withAttributes: priceAttributes)
        yOffset += priceSize.height + 20
        
        // Оригинальная цена (зачеркнутая)
        let originalPriceText = item.originalPrice.currency
        let originalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .regular),
            .foregroundColor: UIColor(ThemeManager.shared.currentTheme.textSecondary),
            .strikethroughStyle: NSUnderlineStyle.single.rawValue
        ]
        let originalSize = originalPriceText.size(withAttributes: originalAttributes)
        let originalRect = CGRect(x: 100, y: yOffset, width: size.width - 200, height: originalSize.height)
        originalPriceText.draw(in: originalRect, withAttributes: originalAttributes)
        yOffset += originalSize.height + 30
        
        // Процент падения
        let dropText = "↓ \(item.dropPercentage.percentString) drop"
        let dropAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 42, weight: .bold),
            .foregroundColor: UIColor(ThemeManager.shared.currentTheme.accent)
        ]
        let dropSize = dropText.size(withAttributes: dropAttributes)
        let dropRect = CGRect(x: 100, y: yOffset, width: size.width - 200, height: dropSize.height)
        dropText.draw(in: dropRect, withAttributes: dropAttributes)
        yOffset += dropSize.height + 20
        
        // Сэкономлено
        let savingsText = "Saved: \(item.savings.currency)"
        let savingsAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
            .foregroundColor: UIColor(ThemeManager.shared.currentTheme.textSecondary)
        ]
        let savingsSize = savingsText.size(withAttributes: savingsAttributes)
        let savingsRect = CGRect(x: 100, y: yOffset, width: size.width - 200, height: savingsSize.height)
        savingsText.draw(in: savingsRect, withAttributes: savingsAttributes)
        yOffset += savingsSize.height
    }
    
    private static func drawStatistics(in context: CGContext, item: WishlistItemEntity, yOffset: inout CGFloat, size: CGSize) {
        let statsY = yOffset
        
        // Целевая цена
        if item.desiredPrice > 0 {
            let targetText = "Target: \(item.desiredPrice.currency)"
            let targetAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .medium),
                .foregroundColor: UIColor(ThemeManager.shared.currentTheme.textSecondary)
            ]
            targetText.draw(at: CGPoint(x: 100, y: statsY), withAttributes: targetAttributes)
        }
        
        // Прогресс к цели
        if item.desiredPrice > 0 && item.originalPrice > item.desiredPrice {
            let progress = min(1.0, max(0.0, (item.originalPrice - item.currentPrice) / (item.originalPrice - item.desiredPrice)))
            let progressText = "\(Int(progress * 100))% to target"
            let progressAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .regular),
                .foregroundColor: UIColor(ThemeManager.shared.currentTheme.textSecondary)
            ]
            progressText.draw(at: CGPoint(x: 100, y: statsY + 40), withAttributes: progressAttributes)
        }
    }
    
    private static func drawFooter(in context: CGContext, size: CGSize) {
        let footerY = size.height - 100
        let footerText = "Price Drop Wishlist Manager"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .medium),
            .foregroundColor: UIColor(ThemeManager.shared.currentTheme.textSecondary).withAlphaComponent(0.6)
        ]
        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerRect = CGRect(x: (size.width - footerSize.width) / 2, y: footerY, width: footerSize.width, height: footerSize.height)
        footerText.draw(in: footerRect, withAttributes: footerAttributes)
    }
}

