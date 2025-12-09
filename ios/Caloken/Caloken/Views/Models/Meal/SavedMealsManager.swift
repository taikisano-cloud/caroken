import SwiftUI
import Combine

// MARK: - 保存した食事データ
struct SavedMeal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var calories: Int
    var protein: Double
    var fat: Double
    var carbs: Double
    var sugar: Double
    var fiber: Double
    var sodium: Double
    var emoji: String
    var imageData: Data?  // ✅ Data型で保存（Codable対応）
    
    init(
        id: UUID = UUID(),
        name: String = "",
        calories: Int = 0,
        protein: Double = 0,
        fat: Double = 0,
        carbs: Double = 0,
        sugar: Double = 0,
        fiber: Double = 0,
        sodium: Double = 0,
        emoji: String = "🍽️",
        imageData: Data? = nil
    ) {
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
        self.imageData = imageData
    }
    
    // ✅ UIImage取得用のcomputed property
    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - 保存した食事マネージャー
final class SavedMealsManager: ObservableObject {
    static let shared = SavedMealsManager()
    
    @Published var savedMeals: [SavedMeal] = []
    
    private let userDefaultsKey = "savedMeals_v2"
    
    private init() {
        loadMeals()
    }
    
    func addMeal(_ meal: SavedMeal) {
        savedMeals.append(meal)
        saveMeals()
        NotificationCenter.default.post(name: .mealAddedToSaved, object: nil)
    }
    
    func removeMeal(_ meal: SavedMeal) {
        savedMeals.removeAll { $0.id == meal.id }
        saveMeals()
    }
    
    func updateMeal(_ meal: SavedMeal) {
        if let index = savedMeals.firstIndex(where: { $0.id == meal.id }) {
            savedMeals[index] = meal
            saveMeals()
        }
    }
    
    func isSaved(name: String) -> Bool {
        savedMeals.contains { $0.name == name }
    }
    
    private func saveMeals() {
        if let data = try? JSONEncoder().encode(savedMeals) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadMeals() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let meals = try? JSONDecoder().decode([SavedMeal].self, from: data) {
            savedMeals = meals
        }
    }
}

// MARK: - 通知名
extension Notification.Name {
    static let mealAddedToSaved = Notification.Name("mealAddedToSaved")
}
