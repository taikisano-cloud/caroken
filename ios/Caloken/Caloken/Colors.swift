import SwiftUI

extension Color {
    // メインカラー
    static let appBackground = Color.white
    static let appText = Color.black
    
    // アクセントカラー（カロちゃんのブラウン）
    static let appBrown = Color(hex: "4A3728")
    
    // サブカラー
    static let appGray = Color(hex: "F5F5F5")
    static let appLightGray = Color(hex: "E0E0E0")
}

// Hexコードから色を生成する拡張
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
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
