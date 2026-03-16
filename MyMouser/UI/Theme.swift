import SwiftUI

struct Theme {
    // Background
    static let bg = Color(hex: "#1a1a2e")
    static let bgCard = Color(hex: "#16213e")
    static let bgCardHover = Color(hex: "#1f3460")
    static let bgSidebar = Color(hex: "#0f1525")
    static let bgInput = Color(hex: "#111827")
    
    // Accent
    static let accent = Color(hex: "#00d4aa")
    static let accentHover = Color(hex: "#00ffc8")
    static let accentDim = Color(hex: "#0d2e26")
    
    // Text
    static let textPrimary = Color(hex: "#e0e0e0")
    static let textSecondary = Color(hex: "#808098")
    static let textDim = Color(hex: "#606078")
    
    // Utility
    static let border = Color(hex: "#2a2a40")
    static let danger = Color(hex: "#ff4466")
    static let success = Color(hex: "#00d4aa")
    static let warning = Color(hex: "#ffaa44")
    
    // Dimensions
    static let radius: CGFloat = 12
    static let fontFamily = "SF Pro Display"
}

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
            (a, r, g, b) = (1, 1, 1, 0)
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
