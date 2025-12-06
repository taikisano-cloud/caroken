import SwiftUI
import Combine

// MARK: - 食事ログのモデル
struct MealLogEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Int
    var protein: Int
    var fat: Int
    var carbs: Int
    var emoji: String
    var date: Date
    var hasImage: Bool
    var isBookmarked: Bool
    var isAnalyzing: Bool  // 分析中フラグ
    
    init(id: UUID = UUID(), name: String, calories: Int, protein: Int, fat: Int, carbs: Int, emoji: String = "🍽️", date: Date = Date(), image: UIImage? = nil, isBookmarked: Bool = false, isAnalyzing: Bool = false) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.emoji = emoji
        self.date = date
        self.hasImage = image != nil
        self.isBookmarked = isBookmarked
        self.isAnalyzing = isAnalyzing
        
        if let image = image {
            MealImageStorage.shared.saveImage(image, for: id)
        }
    }
    
    var image: UIImage? {
        guard hasImage else { return nil }
        return MealImageStorage.shared.loadImage(for: id)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - 画像ストレージ
class MealImageStorage {
    static let shared = MealImageStorage()
    
    private let fileManager = FileManager.default
    private var imageDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = paths[0].appendingPathComponent("MealImages", isDirectory: true)
        
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
        let resizedImage = resizeImage(image, maxSize: 800)
        
        if let data = resizedImage.jpegData(compressionQuality: 0.6) {
            try? data.write(to: url)
        }
    }
    
    func loadImage(for id: UUID) -> UIImage? {
        let url = imageDirectory.appendingPathComponent("\(id.uuidString).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    func imageExists(for id: UUID) -> Bool {
        let url = imageDirectory.appendingPathComponent("\(id.uuidString).jpg")
        return fileManager.fileExists(atPath: url.path)
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

// MARK: - 食事ログマネージャー
class MealLogsManager: ObservableObject {
    static let shared = MealLogsManager()
    
    @Published var allLogs: [MealLogEntry] = []
    
    private let userDefaultsKey = "mealLogEntries_v5"  // バージョンアップ（isAnalyzing追加）
    
    private init() {
        loadLogs()
    }
    
    func logs(for date: Date) -> [MealLogEntry] {
        let calendar = Calendar.current
        return allLogs
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
    
    func totalCalories(for date: Date) -> Int {
        logs(for: date).filter { !$0.isAnalyzing }.reduce(0) { $0 + $1.calories }
    }
    
    func totalNutrients(for date: Date) -> (protein: Int, fat: Int, carbs: Int) {
        let dayLogs = logs(for: date).filter { !$0.isAnalyzing }
        return (
            protein: dayLogs.reduce(0) { $0 + $1.protein },
            fat: dayLogs.reduce(0) { $0 + $1.fat },
            carbs: dayLogs.reduce(0) { $0 + $1.carbs }
        )
    }
    
    func addLog(_ log: MealLogEntry) {
        allLogs.insert(log, at: 0)
        saveLogs()
        NotificationCenter.default.post(name: .mealLogAdded, object: nil)
    }
    
    // 分析中のログを追加して、後で更新する
    func addAnalyzingLog(image: UIImage?, for date: Date) -> UUID {
        let id = UUID()
        let log = MealLogEntry(
            id: id,
            name: "分析中...",
            calories: 0,
            protein: 0,
            fat: 0,
            carbs: 0,
            emoji: "🔄",
            date: date,
            image: image,
            isBookmarked: false,
            isAnalyzing: true
        )
        allLogs.insert(log, at: 0)
        saveLogs()
        NotificationCenter.default.post(name: .mealLogAdded, object: nil)
        return id
    }
    
    // 分析完了後にログを更新
    func completeAnalyzing(id: UUID, name: String, calories: Int, protein: Int, fat: Int, carbs: Int, emoji: String) {
        if let index = allLogs.firstIndex(where: { $0.id == id }) {
            allLogs[index].name = name
            allLogs[index].calories = calories
            allLogs[index].protein = protein
            allLogs[index].fat = fat
            allLogs[index].carbs = carbs
            allLogs[index].emoji = emoji
            allLogs[index].isAnalyzing = false
            saveLogs()
            NotificationCenter.default.post(name: .mealLogUpdated, object: nil)
        }
    }
    
    func updateLog(_ log: MealLogEntry) {
        if let index = allLogs.firstIndex(where: { $0.id == log.id }) {
            allLogs[index] = log
            saveLogs()
            NotificationCenter.default.post(name: .mealLogUpdated, object: nil)
        }
    }
    
    func removeLog(_ log: MealLogEntry) {
        MealImageStorage.shared.deleteImage(for: log.id)
        allLogs.removeAll { $0.id == log.id }
        saveLogs()
    }
    
    func removeLog(id: UUID) {
        MealImageStorage.shared.deleteImage(for: id)
        allLogs.removeAll { $0.id == id }
        saveLogs()
    }
    
    func getLog(id: UUID) -> MealLogEntry? {
        allLogs.first { $0.id == id }
    }
    
    func hasLogs(for date: Date) -> Bool {
        let calendar = Calendar.current
        return allLogs.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([MealLogEntry].self, from: data) {
            allLogs = decoded
        }
    }
}

// MARK: - Notification Names（全アプリ共通）
extension Notification.Name {
    // 食事ログ
    static let mealLogAdded = Notification.Name("mealLogAdded")
    static let mealLogUpdated = Notification.Name("mealLogUpdated")
    static let mealAddedToSaved = Notification.Name("mealAddedToSaved")
    
    // 運動ログ
    static let exerciseLogAdded = Notification.Name("exerciseLogAdded")
    static let exerciseLogUpdated = Notification.Name("exerciseLogUpdated")
    static let exerciseAddedToSaved = Notification.Name("exerciseAddedToSaved")
    
    // 体重ログ
    static let weightLogAdded = Notification.Name("weightLogAdded")
    
    // ユーザープロフィール
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
    static let nutritionGoalsUpdated = Notification.Name("nutritionGoalsUpdated")
    
    // UI制御
    static let showHomeToast = Notification.Name("showHomeToast")
    static let dismissAllMealScreens = Notification.Name("dismissAllMealScreens")
    static let dismissAllExerciseScreens = Notification.Name("dismissAllExerciseScreens")
    static let dismissAllWeightScreens = Notification.Name("dismissAllWeightScreens")
    static let returnToManualEntry = Notification.Name("returnToManualEntry")
}
