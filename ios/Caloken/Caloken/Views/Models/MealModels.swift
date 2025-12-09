import SwiftUI

// MARK: - 食品アイテム
struct FoodItemData: Codable, Identifiable {
    var id = UUID()
    let name: String
    let amount: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let sugar: Double  // 糖分（g）
    let fiber: Double  // 食物繊維（g）
    let sodium: Double // ナトリウム（mg）
    
    enum CodingKeys: String, CodingKey {
        case name, amount, calories, protein, fat, carbs, sugar, fiber, sodium
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
    
    init(name: String, amount: String, calories: Int, protein: Double, fat: Double, carbs: Double, sugar: Double = 0, fiber: Double = 0, sodium: Double = 0) {
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

// MARK: - 食事分析データ
struct MealAnalysisData: Codable {
    let foodItems: [FoodItemData]
    let totalCalories: Int
    let totalProtein: Double
    let totalFat: Double
    let totalCarbs: Double
    let totalSugar: Double     // 糖分合計（g）
    let totalFiber: Double     // 食物繊維合計（g）
    let totalSodium: Double    // ナトリウム合計（mg）
    let characterComment: String
    var mealImage: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case foodItems = "food_items"
        case totalCalories = "total_calories"
        case totalProtein = "total_protein"
        case totalFat = "total_fat"
        case totalCarbs = "total_carbs"
        case totalSugar = "total_sugar"
        case totalFiber = "total_fiber"
        case totalSodium = "total_sodium"
        case characterComment = "character_comment"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        foodItems = try container.decode([FoodItemData].self, forKey: .foodItems)
        totalCalories = try container.decode(Int.self, forKey: .totalCalories)
        totalProtein = try container.decode(Double.self, forKey: .totalProtein)
        totalFat = try container.decode(Double.self, forKey: .totalFat)
        totalCarbs = try container.decode(Double.self, forKey: .totalCarbs)
        totalSugar = try container.decodeIfPresent(Double.self, forKey: .totalSugar) ?? 0
        totalFiber = try container.decodeIfPresent(Double.self, forKey: .totalFiber) ?? 0
        totalSodium = try container.decodeIfPresent(Double.self, forKey: .totalSodium) ?? 0
        characterComment = try container.decode(String.self, forKey: .characterComment)
    }
    
    init(foodItems: [FoodItemData], totalCalories: Int, totalProtein: Double, totalFat: Double, totalCarbs: Double, totalSugar: Double = 0, totalFiber: Double = 0, totalSodium: Double = 0, characterComment: String, mealImage: String? = nil) {
        self.foodItems = foodItems
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalFat = totalFat
        self.totalCarbs = totalCarbs
        self.totalSugar = totalSugar
        self.totalFiber = totalFiber
        self.totalSodium = totalSodium
        self.characterComment = characterComment
        self.mealImage = mealImage
    }
}

// MARK: - 食事ログエントリー
struct MealLogEntry: Identifiable, Codable {
    let id: UUID
    let name: String
    let calories: Int
    let protein: Int
    let fat: Int
    let carbs: Int
    let sugar: Int       // 糖分（g）
    let fiber: Int       // 食物繊維（g）
    let sodium: Int      // ナトリウム（mg）
    let emoji: String
    let date: Date
    var imageData: Data?
    
    var image: UIImage? {
        get {
            guard let data = imageData else { return nil }
            return UIImage(data: data)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, fat, carbs, sugar, fiber, sodium, emoji, date, imageData
    }
    
    init(id: UUID = UUID(), name: String, calories: Int, protein: Int, fat: Int, carbs: Int, sugar: Int = 0, fiber: Int = 0, sodium: Int = 0, emoji: String, date: Date, image: UIImage? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.sugar = sugar
        self.fiber = fiber
        self.sodium = sodium
        self.emoji = emoji
        self.date = date
        self.imageData = image?.jpegData(compressionQuality: 0.5)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Int.self, forKey: .protein)
        fat = try container.decode(Int.self, forKey: .fat)
        carbs = try container.decode(Int.self, forKey: .carbs)
        sugar = try container.decodeIfPresent(Int.self, forKey: .sugar) ?? 0
        fiber = try container.decodeIfPresent(Int.self, forKey: .fiber) ?? 0
        sodium = try container.decodeIfPresent(Int.self, forKey: .sodium) ?? 0
        emoji = try container.decode(String.self, forKey: .emoji)
        date = try container.decode(Date.self, forKey: .date)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }
}

// MARK: - 保存済み食事
struct SavedMeal: Identifiable, Codable {
    let id: UUID
    let name: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let sugar: Double    // 糖分（g）
    let fiber: Double    // 食物繊維（g）
    let sodium: Double   // ナトリウム（mg）
    let emoji: String
    var imageData: Data?
    
    var image: UIImage? {
        get {
            guard let data = imageData else { return nil }
            return UIImage(data: data)
        }
    }
    
    init(id: UUID = UUID(), name: String, calories: Int, protein: Double, fat: Double, carbs: Double, sugar: Double = 0, fiber: Double = 0, sodium: Double = 0, emoji: String, image: UIImage? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.sugar = sugar
        self.fiber = fiber
        self.sodium = sodium
        self.emoji = emoji
        self.imageData = image?.jpegData(compressionQuality: 0.5)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Double.self, forKey: .protein)
        fat = try container.decode(Double.self, forKey: .fat)
        carbs = try container.decode(Double.self, forKey: .carbs)
        sugar = try container.decodeIfPresent(Double.self, forKey: .sugar) ?? 0
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium) ?? 0
        emoji = try container.decode(String.self, forKey: .emoji)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, fat, carbs, sugar, fiber, sodium, emoji, imageData
    }
}

// MARK: - MealLogsManager拡張（栄養素集計対応）
extension MealLogsManager {
    
    /// 指定日の詳細栄養素を取得
    func detailedNutrients(for date: Date) -> (protein: Int, fat: Int, carbs: Int, sugar: Int, fiber: Int, sodium: Int) {
        let dayLogs = logs(for: date)
        let protein = dayLogs.reduce(0) { $0 + $1.protein }
        let fat = dayLogs.reduce(0) { $0 + $1.fat }
        let carbs = dayLogs.reduce(0) { $0 + $1.carbs }
        let sugar = dayLogs.reduce(0) { $0 + $1.sugar }
        let fiber = dayLogs.reduce(0) { $0 + $1.fiber }
        let sodium = dayLogs.reduce(0) { $0 + $1.sodium }
        return (protein, fat, carbs, sugar, fiber, sodium)
    }
}
