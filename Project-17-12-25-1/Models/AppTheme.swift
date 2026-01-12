import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case luminousLight
    case velvetDark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .luminousLight: return "Luminous Light"
        case .velvetDark: return "Velvet Dark"
        }
    }

    var accent: Color {
        switch self {
        case .luminousLight: return Color(hex: "#CBA24A") // soft gold accent
        case .velvetDark: return Color(hex: "#ff9619") // orange accent
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .luminousLight:
            return LinearGradient(colors: [Color(hex: "#FDFBF6"), Color(hex: "#F2E7D5")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .velvetDark:
            return LinearGradient(colors: [Color(hex: "#0F1218"), Color(hex: "#1C222E")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var background: Color {
        switch self {
        case .luminousLight: return Color(hex: "#F7F4EF")
        case .velvetDark: return Color(hex: "#0B0E14")
        }
    }

    var card: Color {
        switch self {
        case .luminousLight: return Color.white.opacity(0.8)
        case .velvetDark: return Color.white.opacity(0.08)
        }
    }

    var textPrimary: Color {
        switch self {
        case .luminousLight: return Color(hex: "#1B1F2A")
        case .velvetDark: return Color.white
        }
    }

    var textSecondary: Color {
        switch self {
        case .luminousLight: return Color(hex: "#4A5163")
        case .velvetDark: return Color.white.opacity(0.7)
        }
    }

    var systemScheme: ColorScheme? {
        switch self {
        case .luminousLight: return .light
        case .velvetDark: return .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            saveTheme()
        }
    }
    
    private let themeKey = "selectedAppTheme"
    
    private init() {
        // Загружаем сохраненную тему при инициализации
        if let savedThemeRaw = UserDefaults.standard.string(forKey: themeKey),
           let savedTheme = AppTheme(rawValue: savedThemeRaw) {
            self.currentTheme = savedTheme
        } else {
            self.currentTheme = .luminousLight
        }
    }
    
    func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
    }
}

