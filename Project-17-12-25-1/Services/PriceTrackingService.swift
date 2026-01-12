import Foundation
import CoreData

/// Сервис для автоматического отслеживания цен
/// Поддерживает интеграцию с различными API и веб-скрапингом
@MainActor
final class PriceTrackingService: ObservableObject {
    static let shared = PriceTrackingService()
    
    @Published var isTracking: Bool = false
    @Published var lastUpdateDate: Date?
    
    private let context: NSManagedObjectContext
    private var trackingTimer: Timer?
    
    private init() {
        self.context = CoreDataStack.shared.context
        loadLastUpdateDate()
    }
    
    // MARK: - Public Methods
    
    /// Начать автоматическое отслеживание цен
    func startTracking(interval: TimeInterval = 3600) { // По умолчанию каждый час
        stopTracking()
        isTracking = true
        
        // Немедленная проверка при старте
        Task { @MainActor in
            await checkAllPrices()
        }
        
        // Периодическая проверка
        trackingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAllPrices()
            }
        }
    }
    
    /// Остановить отслеживание
    func stopTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        isTracking = false
    }
    
    /// Проверить цены для всех активных товаров
    func checkAllPrices() async {
        let request = NSFetchRequest<WishlistItemEntity>(entityName: "WishlistItemEntity")
        request.predicate = NSPredicate(format: "isArchived == NO AND isBought == NO")
        
        do {
            let items = try context.fetch(request)
            var updatedCount = 0
            
            for item in items {
                if let newPrice = await fetchPrice(for: item) {
                    if abs(newPrice - item.currentPrice) > 0.01 { // Изменение больше 1 цента
                        updatePrice(for: item, newPrice: newPrice)
                        updatedCount += 1
                    }
                }
            }
            
            lastUpdateDate = Date()
            saveLastUpdateDate()
            
            if updatedCount > 0 {
                // Отправить уведомления о изменениях
                await sendPriceChangeNotifications(updatedCount: updatedCount)
            }
        } catch {
            print("Price tracking error: \(error)")
        }
    }
    
    /// Проверить цену для конкретного товара
    func checkPrice(for item: WishlistItemEntity) async -> Double? {
        return await fetchPrice(for: item)
    }
    
    // MARK: - Private Methods
    
    /// Получить цену для товара (с поддержкой различных источников)
    private func fetchPrice(for item: WishlistItemEntity) async -> Double? {
        // Приоритет 1: URL из storeNote (если это ссылка)
        if let storeNote = item.storeNote,
           let url = URL(string: storeNote),
           url.scheme != nil {
            return await fetchPriceFromURL(url, itemName: item.name)
        }
        
        // Приоритет 2: Интеграция с API (можно расширить)
        if let apiPrice = await fetchPriceFromAPI(for: item) {
            return apiPrice
        }
        
        // Приоритет 3: Умное извлечение из storeNote
        if let storeNote = item.storeNote {
            return extractPriceFromText(storeNote)
        }
        
        return nil
    }
    
    /// Получить цену из URL (базовая реализация для демонстрации)
    private func fetchPriceFromURL(_ url: URL, itemName: String) async -> Double? {
        // В реальной реализации здесь будет веб-скрапинг или API вызов
        // Для демонстрации возвращаем nil, но структура готова для интеграции
        
        // Пример интеграции с Amazon Product Advertising API:
        // return await AmazonAPI.fetchPrice(asin: extractASIN(from: url))
        
        // Пример веб-скрапинга:
        // return await WebScraper.extractPrice(from: url, selector: ".price")
        
        return nil
    }
    
    /// Получить цену через API
    private func fetchPriceFromAPI(for item: WishlistItemEntity) async -> Double? {
        // Место для интеграции с различными API:
        // - Amazon Product Advertising API
        // - eBay API
        // - PriceAPI.com
        // - Keepa API
        
        // Пример структуры:
        /*
        if let amazonURL = extractAmazonURL(from: item.storeNote) {
            return await AmazonAPI.fetchPrice(asin: extractASIN(from: amazonURL))
        }
        */
        
        return nil
    }
    
    /// Извлечь цену из текста (fallback метод)
    private func extractPriceFromText(_ text: String) -> Double? {
        // Простое извлечение цены из текста
        let pattern = #"(\$|€|£|¥|₽|USD|EUR|GBP|JPY|RUB)?\s*(\d+[.,]\d{2})"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range),
           let priceRange = Range(match.range(at: 2), in: text) {
            let priceString = String(text[priceRange]).replacingOccurrences(of: ",", with: ".")
            return Double(priceString)
        }
        
        return nil
    }
    
    /// Обновить цену товара
    private func updatePrice(for item: WishlistItemEntity, newPrice: Double) {
        let oldPrice = item.currentPrice
        item.currentPrice = newPrice
        
        // Создать запись об обновлении
        let update = PriceUpdateEntity(context: context)
        update.id = UUID()
        update.price = newPrice
        update.date = Date()
        update.item = item
        
        let mutable = item.mutableOrderedSetValue(forKey: "priceUpdates")
        mutable.add(update)
        
        do {
            try context.save()
            print("Price updated for \(item.name): \(oldPrice) -> \(newPrice)")
        } catch {
            print("Failed to save price update: \(error)")
        }
    }
    
    /// Отправить уведомления об изменениях цен
    private func sendPriceChangeNotifications(updatedCount: Int) async {
        // Здесь будет интеграция с системой уведомлений
        // NotificationService.shared.sendPriceUpdateNotification(count: updatedCount)
    }
    
    // MARK: - Persistence
    
    private func saveLastUpdateDate() {
        UserDefaults.standard.set(lastUpdateDate, forKey: "priceTrackingLastUpdate")
    }
    
    private func loadLastUpdateDate() {
        lastUpdateDate = UserDefaults.standard.object(forKey: "priceTrackingLastUpdate") as? Date
    }
}

// MARK: - Helper Extensions

extension PriceTrackingService {
    /// Извлечь ASIN из Amazon URL
    func extractASIN(from url: URL) -> String? {
        // Реализация извлечения ASIN из Amazon URL
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let path = components.path.split(separator: "/").first(where: { $0.count == 10 }) {
            return String(path)
        }
        return nil
    }
    
    /// Проверить, является ли URL Amazon
    func isAmazonURL(_ url: URL) -> Bool {
        return url.host?.contains("amazon") == true
    }
}
