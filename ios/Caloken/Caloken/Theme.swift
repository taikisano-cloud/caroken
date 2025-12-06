import SwiftUI

// MARK: - Hexコードから色を生成する拡張
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

// MARK: - ダークモード対応カラー
// これらのカラーは自動的にダーク/ライトモードに対応します

extension Color {
    // MARK: - 背景色
    
    /// メイン背景色（ライト: 白、ダーク: システム背景）
    static let appBackground = Color(UIColor.systemBackground)
    
    /// セカンダリ背景色（カード等）
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    
    /// 三次背景色（入れ子のカード等）
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - テキスト色
    
    /// プライマリテキスト（ライト: 黒、ダーク: 白）
    static let appPrimaryText = Color(UIColor.label)
    
    /// セカンダリテキスト
    static let appSecondaryText = Color(UIColor.secondaryLabel)
    
    /// 三次テキスト
    static let appTertiaryText = Color(UIColor.tertiaryLabel)
    
    // MARK: - ブランドカラー（カロちゃん）
    
    /// アクセントカラー（オレンジ）
    static let appAccent = Color.orange
    
    /// カロちゃんのブラウン
    static let appBrown = Color(hex: "4A3728")
    
    // MARK: - その他のカラー
    
    /// 成功色
    static let appSuccess = Color.green
    
    /// 警告色
    static let appWarning = Color.yellow
    
    /// エラー色
    static let appError = Color.red
    
    // MARK: - UI要素
    
    /// ボタン背景（プライマリ）
    static let buttonPrimary = Color.orange
    
    /// ボタン背景（セカンダリ）
    static let buttonSecondary = Color(UIColor.systemGray5)
    
    /// ボタンテキスト（プライマリボタン上）
    static let buttonPrimaryText = Color.white
    
    /// 区切り線
    static let appDivider = Color(UIColor.separator)
    
    /// グレー背景
    static let appGray = Color(UIColor.systemGray6)
    
    /// ライトグレー
    static let appLightGray = Color(UIColor.systemGray5)
    
    // MARK: - 固定色（ダークモードでも変わらない）
    
    /// 常に白
    static let alwaysWhite = Color.white
    
    /// 常に黒
    static let alwaysBlack = Color.black
    
    /// オーバーレイ（半透明黒）
    static let overlay = Color.black.opacity(0.3)
}

// MARK: - カラーセット（特定のUI用）
struct AppColors {
    // グラフ用カラー
    static let chartOrange = Color.orange
    static let chartGreen = Color.green
    static let chartBlue = Color.blue
    static let chartRed = Color.red
    
    // 栄養素カラー
    static let calories = Color.orange
    static let protein = Color.red.opacity(0.8)
    static let carbs = Color.orange
    static let fat = Color.blue
    
    // 進捗カラー
    static let progressActive = Color.orange
    static let progressInactive = Color(UIColor.systemGray4)
}
