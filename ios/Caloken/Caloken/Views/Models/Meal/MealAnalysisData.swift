import Foundation

// MARK: - 食事分析結果
struct MealAnalysisData: Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case foodItems = "food_items"
        case totalCalories = "total_calories"
        case totalProtein = "total_protein"
        case totalFat = "total_fat"
        case totalCarbs = "total_carbs"
        case totalSugar = "total_sugar"
        case totalFiber = "total_fiber"
        case totalSodium = "total_sodium"
        case mealImage = "meal_image"
        case characterComment = "character_comment"
    }
    
    // デフォルト値付きデコード（後方互換性）
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        foodItems = try container.decode([MealFoodItem].self, forKey: .foodItems)
        totalCalories = try container.decode(Int.self, forKey: .totalCalories)
        totalProtein = try container.decode(Double.self, forKey: .totalProtein)
        totalFat = try container.decode(Double.self, forKey: .totalFat)
        totalCarbs = try container.decode(Double.self, forKey: .totalCarbs)
        totalSugar = try container.decodeIfPresent(Double.self, forKey: .totalSugar) ?? 0
        totalFiber = try container.decodeIfPresent(Double.self, forKey: .totalFiber) ?? 0
        totalSodium = try container.decodeIfPresent(Double.self, forKey: .totalSodium) ?? 0
        mealImage = try container.decodeIfPresent(String.self, forKey: .mealImage)
        characterComment = try container.decode(String.self, forKey: .characterComment)
    }
    
    // 通常のイニシャライザ
    init(
        foodItems: [MealFoodItem],
        totalCalories: Int,
        totalProtein: Double,
        totalFat: Double,
        totalCarbs: Double,
        totalSugar: Double = 0,
        totalFiber: Double = 0,
        totalSodium: Double = 0,
        mealImage: String? = nil,
        characterComment: String
    ) {
        self.foodItems = foodItems
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalFat = totalFat
        self.totalCarbs = totalCarbs
        self.totalSugar = totalSugar
        self.totalFiber = totalFiber
        self.totalSodium = totalSodium
        self.mealImage = mealImage
        self.characterComment = characterComment
    }
}

// MARK: - 食品アイテム
struct MealFoodItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let amount: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let sugar: Double
    let fiber: Double
    let sodium: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, calories, protein, fat, carbs, sugar, fiber, sodium
    }
    
    // デフォルト値付きデコード
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(String.self, forKey: .amount)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Double.self, forKey: .protein)
        fat = try container.decode(Double.self, forKey: .fat)
        carbs = try container.decode(Double.self, forKey: .carbs)
        sugar = try container.decodeIfPresent(Double.self, forKey: .sugar) ?? 0
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium) ?? 0
    }
    
    // 通常のイニシャライザ
    init(
        id: UUID = UUID(),
        name: String,
        amount: String,
        calories: Int,
        protein: Double,
        fat: Double,
        carbs: Double,
        sugar: Double = 0,
        fiber: Double = 0,
        sodium: Double = 0
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.sugar = sugar
        self.fiber = fiber
        self.sodium = sodium
    }
}
