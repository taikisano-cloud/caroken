import SwiftUI
import Combine

// MARK: - 保存済み食事のモデル（画像対応）
struct SavedMeal: Identifiable, Codable {
    let id: UUID
    let name: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let emoji: String
    let savedAt: Date
    let hasImage: Bool  // 画像があるかどうか
    
    init(id: UUID = UUID(), name: String, calories: Int, protein: Double, fat: Double, carbs: Double, emoji: String = "🍽️", savedAt: Date = Date(), image: UIImage? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.emoji = emoji
        self.savedAt = savedAt
        self.hasImage = image != nil
        
        // 画像を保存
        if let image = image {
            SavedMealImageStorage.shared.saveImage(image, for: id)
        }
    }
    
    // 画像を取得
    var image: UIImage? {
        guard hasImage else { return nil }
        return SavedMealImageStorage.shared.loadImage(for: id)
    }
}

// MARK: - 保存済み食事の画像ストレージ
class SavedMealImageStorage {
    static let shared = SavedMealImageStorage()
    
    private let fileManager = FileManager.default
    private var imageDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = paths[0].appendingPathComponent("SavedMealImages", isDirectory: true)
        
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        return directory
    }
    
    private init() {
        _ = imageDirectory
    }
    
    func saveImage(_ image: UIImage, for id: UUID) {
        let url = imageDirectory.appendingPathComponent("\(id.uuidString).jpg")
        let resizedImage = resizeImage(image, maxSize: 400)
        
        if let data = resizedImage.jpegData(compressionQuality: 0.6) {
            try? data.write(to: url)
        }
    }
    
    func loadImage(for id: UUID) -> UIImage? {
        let url = imageDirectory.appendingPathComponent("\(id.uuidString).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    func deleteImage(for id: UUID) {
        let url = imageDirectory.appendingPathComponent("\(id.uuidString).jpg")
        try? fileManager.removeItem(at: url)
    }
    
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        if ratio >= 1 { return image }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - 保存済み食事マネージャー
class SavedMealsManager: ObservableObject {
    static let shared = SavedMealsManager()
    
    @Published var savedMeals: [SavedMeal] = []
    
    private let userDefaultsKey = "savedMeals_v3"  // バージョンアップ（画像対応）
    
    private init() {
        loadMeals()
    }
    
    func addMeal(_ meal: SavedMeal) {
        objectWillChange.send()
        savedMeals.insert(meal, at: 0)
        saveMeals()
        NotificationCenter.default.post(name: .mealAddedToSaved, object: nil)
        print("📚 保存済みに追加: \(meal.name), 画像あり: \(meal.hasImage), 現在の件数: \(savedMeals.count)")
    }
    
    func removeMeal(_ meal: SavedMeal) {
        objectWillChange.send()
        // 画像も削除
        SavedMealImageStorage.shared.deleteImage(for: meal.id)
        savedMeals.removeAll { $0.id == meal.id }
        saveMeals()
    }
    
    func removeMeal(at offsets: IndexSet) {
        objectWillChange.send()
        for index in offsets {
            let meal = savedMeals[index]
            SavedMealImageStorage.shared.deleteImage(for: meal.id)
        }
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
