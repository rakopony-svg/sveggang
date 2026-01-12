import Foundation
import CoreData

/// Сервис для предсказания цен на основе исторических данных
@MainActor
final class PricePredictionService {
    static let shared = PricePredictionService()
    
    private init() {}
    
    /// Предсказать будущую цену на основе тренда
    func predictPrice(for item: WishlistItemEntity, daysAhead: Int = 7) -> PricePrediction? {
        let updates = item.priceUpdatesArray.sorted { $0.date < $1.date }
        
        guard updates.count >= 2 else {
            return nil // Недостаточно данных для предсказания
        }
        
        // Вычисляем тренд (линейная регрессия)
        let trend = calculateTrend(updates: updates)
        
        // Предсказанная цена через N дней
        let predictedPrice = item.currentPrice + (trend * Double(daysAhead))
        
        // Вероятность падения цены
        let dropProbability = calculateDropProbability(updates: updates, trend: trend)
        
        // Рекомендация
        let recommendation = generateRecommendation(
            currentPrice: item.currentPrice,
            predictedPrice: predictedPrice,
            desiredPrice: item.desiredPrice,
            dropProbability: dropProbability
        )
        
        return PricePrediction(
            predictedPrice: max(0, predictedPrice),
            daysAhead: daysAhead,
            trend: trend,
            dropProbability: dropProbability,
            recommendation: recommendation
        )
    }
    
    /// Вычислить тренд (изменение цены в день)
    private func calculateTrend(updates: [PriceUpdateEntity]) -> Double {
        guard updates.count >= 2 else { return 0 }
        
        let prices = updates.map { $0.price }
        let dates = updates.map { $0.date.timeIntervalSince1970 }
        
        // Простая линейная регрессия
        let n = Double(updates.count)
        let sumX = dates.reduce(0, +)
        let sumY = prices.reduce(0, +)
        let sumXY = zip(dates, prices).map(*).reduce(0, +)
        let sumX2 = dates.map { $0 * $0 }.reduce(0, +)
        
        let denominator = (n * sumX2) - (sumX * sumX)
        guard denominator != 0 else { return 0 }
        
        let slope = ((n * sumXY) - (sumX * sumY)) / denominator
        
        // Конвертируем в изменение цены в день
        return slope * 86400 // секунды в день
    }
    
    /// Вычислить вероятность падения цены
    private func calculateDropProbability(updates: [PriceUpdateEntity], trend: Double) -> Double {
        guard updates.count >= 2 else { return 0.5 }
        
        // Считаем количество падений
        var drops = 0
        for i in 1..<updates.count {
            if updates[i].price < updates[i-1].price {
                drops += 1
            }
        }
        
        let dropRatio = Double(drops) / Double(updates.count - 1)
        
        // Учитываем тренд
        let trendFactor = trend < 0 ? 0.3 : -0.1 // Если тренд падающий, увеличиваем вероятность
        
        return min(1.0, max(0.0, dropRatio + trendFactor))
    }
    
    /// Сгенерировать рекомендацию
    private func generateRecommendation(
        currentPrice: Double,
        predictedPrice: Double,
        desiredPrice: Double,
        dropProbability: Double
    ) -> String {
        if predictedPrice <= desiredPrice {
            return "Great news! Price is predicted to reach your target soon. Consider waiting."
        } else if dropProbability > 0.7 {
            return "High probability of price drop. Wait a bit longer."
        } else if dropProbability > 0.4 {
            return "Moderate chance of price drop. Monitor closely."
        } else if predictedPrice < currentPrice {
            return "Price may drop slightly. Consider waiting."
        } else {
            return "Price trend is stable or rising. Consider buying now if it fits your budget."
        }
    }
}

// MARK: - Price Prediction Model

struct PricePrediction {
    let predictedPrice: Double
    let daysAhead: Int
    let trend: Double // Изменение цены в день
    let dropProbability: Double // 0.0 - 1.0
    let recommendation: String
}
