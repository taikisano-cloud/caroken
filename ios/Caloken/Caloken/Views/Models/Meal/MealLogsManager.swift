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
    var sugar: Int       // 糖分（g）← 追加
    var fiber: Int       // 食物繊維（g）← 追加
    var sodium: Int      // ナトリウム（mg）← 追加
    var emoji: String
    var date: Date
    var hasImage: Bool
    var isBookmarked: Bool
    var isAnalyzing: Bool
    var analyzingStartedAt: Date?
    var isAnalyzingError: Bool
    
    // タイムアウト時間（秒）
    static let analysisTimeout: TimeInterval = 30
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Int,
        fat: Int,
        carbs: Int,
        sugar: Int = 0,
        fiber: Int = 0,
        sodium: Int = 0,
        emoji: String = "🍽️",
        date: Date = Date(),
        image: UIImage? = nil,
        isBookmarked: Bool = false,
        isAnalyzing: Bool = false,
        analyzingStartedAt: Date? = nil,
        isAnalyzingError: Bool = false
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
        self.date = date
        self.hasImage = image != nil
        self.isBookmarked = isBookmarked
        self.isAnalyzing = isAnalyzing
        self.analyzingStartedAt = isAnalyzing ? (analyzingStartedAt ?? Date()) : nil
        self.isAnalyzingError = isAnalyzingError
        
        if let image = image {
            MealImageStorage.shared.saveImage(image, for: id)
        }
    }
    
    // Codable: 後方互換性のためのデコード
    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, fat, carbs, sugar, fiber, sodium
        case emoji, date, hasImage, isBookmarked, isAnalyzing, analyzingStartedAt, isAnalyzingError
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Int.self, forKey: .protein)
        fat = try container.decode(Int.self, forKey: .fat)
        carbs = try container.decode(Int.self, forKey: .carbs)
        // 新フィールド: なければ0（後方互換性）
        sugar = try container.decodeIfPresent(Int.self, forKey: .sugar) ?? 0
        fiber = try container.decodeIfPresent(Int.self, forKey: .fiber) ?? 0
        sodium = try container.decodeIfPresent(Int.self, forKey: .sodium) ?? 0
        emoji = try container.decode(String.self, forKey: .emoji)
        date = try container.decode(Date.self, forKey: .date)
        hasImage = try container.decode(Bool.self, forKey: .hasImage)
        isBookmarked = try container.decodeIfPresent(Bool.self, forKey: .isBookmarked) ?? false
        isAnalyzing = try container.decodeIfPresent(Bool.self, forKey: .isAnalyzing) ?? false
        analyzingStartedAt = try container.decodeIfPresent(Date.self, forKey: .analyzingStartedAt)
        isAnalyzingError = try container.decodeIfPresent(Bool.self, forKey: .isAnalyzingError) ?? false
    }
    
    // タイムアウトしているかどうか
    var hasTimedOut: Bool {
        guard isAnalyzing, let startedAt = analyzingStartedAt else { return false }
        return Date().timeIntervalSince(startedAt) > MealLogEntry.analysisTimeout
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
    
    // バージョンアップ（sugar/fiber/sodium追加）
    private let userDefaultsKey = "mealLogEntries_v6"
    private let oldUserDefaultsKey = "mealLogEntries_v5"
    
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
    
    /// 詳細栄養素を取得（sugar/fiber/sodium含む）
    func detailedNutrients(for date: Date) -> (protein: Int, fat: Int, carbs: Int, sugar: Int, fiber: Int, sodium: Int) {
        let dayLogs = logs(for: date).filter { !$0.isAnalyzing }
        return (
            protein: dayLogs.reduce(0) { $0 + $1.protein },
            fat: dayLogs.reduce(0) { $0 + $1.fat },
            carbs: dayLogs.reduce(0) { $0 + $1.carbs },
            sugar: dayLogs.reduce(0) { $0 + $1.sugar },
            fiber: dayLogs.reduce(0) { $0 + $1.fiber },
            sodium: dayLogs.reduce(0) { $0 + $1.sodium }
        )
    }
    
    func addLog(_ log: MealLogEntry) {
        allLogs.insert(log, at: 0)
        saveLogs()
        NotificationCenter.default.post(name: .mealLogAdded, object: nil)
    }
    
    // 分析中のログを追加
    func addAnalyzingLog(image: UIImage?, for date: Date) -> UUID {
        let id = UUID()
        let log = MealLogEntry(
            id: id,
            name: "分析中...",
            calories: 0,
            protein: 0,
            fat: 0,
            carbs: 0,
            sugar: 0,
            fiber: 0,
            sodium: 0,
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
    
    // 分析完了後にログを更新（sugar/fiber/sodium対応）
    func completeAnalyzing(
        id: UUID,
        name: String,
        calories: Int,
        protein: Int,
        fat: Int,
        carbs: Int,
        sugar: Int = 0,
        fiber: Int = 0,
        sodium: Int = 0,
        emoji: String
    ) {
        if let index = allLogs.firstIndex(where: { $0.id == id }) {
            allLogs[index].name = name
            allLogs[index].calories = calories
            allLogs[index].protein = protein
            allLogs[index].fat = fat
            allLogs[index].carbs = carbs
            allLogs[index].sugar = sugar
            allLogs[index].fiber = fiber
            allLogs[index].sodium = sodium
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
    
    // 分析エラーをセット
    func setAnalyzingError(id: UUID) {
        if let index = allLogs.firstIndex(where: { $0.id == id }) {
            allLogs[index].isAnalyzingError = true
            allLogs[index].isAnalyzing = false
            saveLogs()
            NotificationCenter.default.post(name: .mealLogUpdated, object: nil)
        }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadLogs() {
        // 新バージョンのデータを試す
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([MealLogEntry].self, from: data) {
            allLogs = decoded
            return
        }
        
        // 旧バージョンからのマイグレーション
        if let data = UserDefaults.standard.data(forKey: oldUserDefaultsKey),
           let decoded = try? JSONDecoder().decode([MealLogEntry].self, from: data) {
            allLogs = decoded
            // 新バージョンで保存し直す
            saveLogs()
            // 旧データを削除
            UserDefaults.standard.removeObject(forKey: oldUserDefaultsKey)
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
