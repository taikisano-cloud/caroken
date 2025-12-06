import Foundation

// MARK: - 食事分析結果
struct MealAnalysisData {
    let foodItems: [MealFoodItem]
    let totalCalories: Int
    let totalProtein: Double
    let totalFat: Double
    let totalCarbs: Double
    let totalSugar: Double
    let totalFiber: Double
    let totalSodium: Double
    let mealImage: String?
    let characterComment: String
}

// MARK: - 食品アイテム
struct MealFoodItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let sugar: Double
    let fiber: Double
    let sodium: Double
}
