import SwiftUI
import UIKit

/// 앱 컬러 테마
enum AppColors {
    // Brand Colors
    static let brandPrimary = Color(hex: "#00C896")
    static let brandSecondary = Color(hex: "#00A478")
    static let brandTertiary = Color(hex: "#008C64")
    
    // Status Colors
    static let success = Color(hex: "#4CAF50")
    static let warning = Color(hex: "#FFC107")
    static let error = Color(hex: "#F44336")
    static let info = Color(hex: "#2196F3")
    
    // Order Status Colors
    static let pending = Color(hex: "#9E9E9E")
    static let assigned = Color(hex: "#2196F3")
    static let accepted = Color(hex: "#FF9800")
    static let pickingUp = Color(hex: "#FFC107")
    static let delivering = Color(hex: "#4CAF50")
    static let completed = Color(hex: "#8BC34A")
    static let cancelled = Color(hex: "#F44336")
    
    // Grayscale
    static let gray50 = Color(hex: "#FAFAFA")
    static let gray100 = Color(hex: "#F5F5F5")
    static let gray200 = Color(hex: "#EEEEEE")
    static let gray300 = Color(hex: "#E0E0E0")
    static let gray400 = Color(hex: "#BDBDBD")
    static let gray500 = Color(hex: "#9E9E9E")
    static let gray600 = Color(hex: "#757575")
    static let gray700 = Color(hex: "#616161")
    static let gray800 = Color(hex: "#424242")
    static let gray900 = Color(hex: "#212121")
    
    // Background
    static let background = Color(hex: "#FFFFFF")
    static let backgroundSecondary = Color(hex: "#F5F5F5")
    static let backgroundTertiary = Color(hex: "#EEEEEE")
    
    // Text
    static let textPrimary = Color(hex: "#212121")
    static let textSecondary = Color(hex: "#757575")
    static let textTertiary = Color(hex: "#9E9E9E")
    static let textOnPrimary = Color(hex: "#FFFFFF")
    
    // Divider
    static let divider = Color(hex: "#E0E0E0")
    static let dividerLight = Color(hex: "#F5F5F5")
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Extension

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}