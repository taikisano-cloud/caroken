import SwiftUI
import Combine

// MARK: - 保存済み食事のモデル
struct SavedMeal: Identifiable, Codable {
    let id: UUID
    let name: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let emoji: String
    let savedAt: Date
    
    init(id: UUID = UUID(), name: String, calories: Int, protein: Double, fat: Double, carbs: Double, emoji: String = "🍽️", savedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.emoji = emoji
        self.savedAt = savedAt
    }
}

// MARK: - 保存済み食事マネージャー
class SavedMealsManager: ObservableObject {
    static let shared = SavedMealsManager()
    
    @Published var savedMeals: [SavedMeal] = []
    
    private let userDefaultsKey = "savedMeals_v2"
    
    private init() {
        loadMeals()
    }
    
    func addMeal(_ meal: SavedMeal) {
        // 明示的に変更を通知
        objectWillChange.send()
        
        // 常に先頭に追加（重複チェックなし）
        savedMeals.insert(meal, at: 0)
        saveMeals()
        
        // 通知を送信
        NotificationCenter.default.post(name: .mealAddedToSaved, object: nil)
        print("📚 保存済みに追加: \(meal.name), 現在の件数: \(savedMeals.count)")
    }
    
    func removeMeal(_ meal: SavedMeal) {
        objectWillChange.send()
        savedMeals.removeAll { $0.id == meal.id }
        saveMeals()
    }
    
    func removeMeal(at offsets: IndexSet) {
        objectWillChange.send()
        savedMeals.remove(atOffsets: offsets)
        saveMeals()
    }
    
    func hasMeal(named name: String) -> Bool {
        savedMeals.contains { $0.name == name }
    }
    
    private func saveMeals() {
        if let encoded = try? JSONEncoder().encode(savedMeals) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 保存済み食事を保存: \(savedMeals.count)件")
        }
    }
    
    private func loadMeals() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([SavedMeal].self, from: data) {
            savedMeals = decoded
            print("📂 保存済み食事を読み込み: \(savedMeals.count)件")
        }
    }
}
