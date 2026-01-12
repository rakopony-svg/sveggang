import SwiftUI

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

extension Double {
    var currency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let stored = UserDefaults.standard.string(forKey: "currencyCode")
        formatter.currencyCode = stored ?? Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$0"
    }

    var percentString: String {
        String(format: "%.0f%%", self * 100)
    }
}

extension View {
    func glassBackground(opacity: Double = 0.12) -> some View {
        self
            .background(.ultraThinMaterial.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    func themedCard() -> some View {
        self
            .padding()
            .background(ThemeManager.shared.currentTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

