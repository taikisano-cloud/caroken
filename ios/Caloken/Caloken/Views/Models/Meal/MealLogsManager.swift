import SwiftUI
import Combine

// MARK: - 食事ログのエントリー
struct MealLogEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var calories: Int
    var protein: Int
    var fat: Int
    var carbs: Int
    var sugar: Int          // ✅ 糖質
    var fiber: Int          // ✅ 食物繊維
    var sodium: Int         // ✅ ナトリウム(mg)
    var emoji: String
    var date: Date
    var time: Date
    var image: Data?
    var isAnalyzing: Bool
    var isAnalyzingError: Bool  // ✅ 追加
    var hasTimedOut: Bool       // ✅ 追加
    var analysisProgress: Int   // ✅ 分析進捗（0-100%）
    
    // ✅ iconはemojiを返す（互換性のため）
    var icon: String {
        emoji
    }
    
    // ✅ UIImage取得用（Data→UIImage変換）
    var uiImage: UIImage? {
        guard let data = image else { return nil }
        return UIImage(data: data)
    }
    
    // ✅ 時刻文字列
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    // ✅ 後方互換性のあるイニシャライザ
    init(
        id: UUID = UUID(),
        name: String = "",
        calories: Int = 0,
        protein: Int = 0,
        fat: Int = 0,
        carbs: Int = 0,
        sugar: Int = 0,
        fiber: Int = 0,
        sodium: Int = 0,
        emoji: String = "🍽️",
        date: Date = Date(),
        time: Date? = nil,
        image: Data? = nil,
        isAnalyzing: Bool = false,
        isAnalyzingError: Bool = false,
        hasTimedOut: Bool = false,
        analysisProgress: Int = 0
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
        self.time = time ?? date
        self.image = image
        self.isAnalyzing = isAnalyzing
        self.isAnalyzingError = isAnalyzingError
        self.hasTimedOut = hasTimedOut
        self.analysisProgress = analysisProgress
    }
    
    // ✅ Codable - 旧データ対応
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
        time = try container.decodeIfPresent(Date.self, forKey: .time) ?? date
        image = try container.decodeIfPresent(Data.self, forKey: .image)
        isAnalyzing = try container.decodeIfPresent(Bool.self, forKey: .isAnalyzing) ?? false
        isAnalyzingError = try container.decodeIfPresent(Bool.self, forKey: .isAnalyzingError) ?? false
        hasTimedOut = try container.decodeIfPresent(Bool.self, forKey: .hasTimedOut) ?? false
        analysisProgress = try container.decodeIfPresent(Int.self, forKey: .analysisProgress) ?? 0
    }
}

// MARK: - 食事ログマネージャー
final class MealLogsManager: ObservableObject {
    static let shared = MealLogsManager()
    
    @Published private(set) var allLogs: [MealLogEntry] = []
    
    private let userDefaultsKey = "mealLogs"
    
    private init() {
        loadLogs()
    }
    
    // MARK: - 日付でフィルタリング
    func logs(for date: Date) -> [MealLogEntry] {
        let calendar = Calendar.current
        return allLogs.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.time > $1.time }
    }
    
    // MARK: - ログ追加
    func addLog(_ log: MealLogEntry) {
        allLogs.append(log)
        saveLogs()
        NotificationCenter.default.post(name: .mealLogAdded, object: nil)
    }
    
    // MARK: - 分析中ログ追加
    func addAnalyzingLog(image: UIImage?, for date: Date) -> UUID {
        let imageData = image?.jpegData(compressionQuality: 0.7)
        let log = MealLogEntry(
            name: "",
            calories: 0,
            protein: 0,
            fat: 0,
            carbs: 0,
            sugar: 0,
            fiber: 0,
            sodium: 0,
            emoji: "🔄",
            date: date,
            time: Date(),
            image: imageData,
            isAnalyzing: true
        )
        allLogs.append(log)
        saveLogs()
        return log.id
    }
    
    // MARK: - 分析完了 ✅ sugar/fiber/sodium対応
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
            allLogs[index].analysisProgress = 100
            saveLogs()
            NotificationCenter.default.post(name: .mealLogUpdated, object: nil)
        }
    }
    
    // MARK: - 分析進捗更新
    func updateAnalysisProgress(id: UUID, progress: Int) {
        if let index = allLogs.firstIndex(where: { $0.id == id }) {
            allLogs[index].analysisProgress = min(max(progress, 0), 100)
            // saveLogs()は頻繁に呼ばないように
        }
    }
    
    // MARK: - ログ更新
    func updateLog(_ log: MealLogEntry) {
        if let index = allLogs.firstIndex(where: { $0.id == log.id }) {
            allLogs[index] = log
            saveLogs()
            NotificationCenter.default.post(name: .mealLogUpdated, object: nil)
        }
    }
    
    // MARK: - ログ削除
    func removeLog(id: UUID) {
        allLogs.removeAll { $0.id == id }
        saveLogs()
        NotificationCenter.default.post(name: .mealLogDeleted, object: nil)
    }
    
    // MARK: - 永続化
    private func saveLogs() {
        if let data = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let logs = try? JSONDecoder().decode([MealLogEntry].self, from: data) {
            allLogs = logs
        }
    }
    
    // MARK: - 今日の合計
    func todayTotals() -> (calories: Int, protein: Int, fat: Int, carbs: Int, sugar: Int, fiber: Int, sodium: Int) {
        let todayLogs = logs(for: Date()).filter { !$0.isAnalyzing }
        return (
            calories: todayLogs.reduce(0) { $0 + $1.calories },
            protein: todayLogs.reduce(0) { $0 + $1.protein },
            fat: todayLogs.reduce(0) { $0 + $1.fat },
            carbs: todayLogs.reduce(0) { $0 + $1.carbs },
            sugar: todayLogs.reduce(0) { $0 + $1.sugar },
            fiber: todayLogs.reduce(0) { $0 + $1.fiber },
            sodium: todayLogs.reduce(0) { $0 + $1.sodium }
        )
    }
    
    // MARK: - 特定日の合計
    func totals(for date: Date) -> (calories: Int, protein: Int, fat: Int, carbs: Int, sugar: Int, fiber: Int, sodium: Int) {
        let dateLogs = logs(for: date).filter { !$0.isAnalyzing }
        return (
            calories: dateLogs.reduce(0) { $0 + $1.calories },
            protein: dateLogs.reduce(0) { $0 + $1.protein },
            fat: dateLogs.reduce(0) { $0 + $1.fat },
            carbs: dateLogs.reduce(0) { $0 + $1.carbs },
            sugar: dateLogs.reduce(0) { $0 + $1.sugar },
            fiber: dateLogs.reduce(0) { $0 + $1.fiber },
            sodium: dateLogs.reduce(0) { $0 + $1.sodium }
        )
    }
    
    // MARK: - 特定日のカロリー合計
    func totalCalories(for date: Date) -> Int {
        logs(for: date).filter { !$0.isAnalyzing }.reduce(0) { $0 + $1.calories }
    }
    
    // MARK: - 特定日の栄養素合計（基本）
    func totalNutrients(for date: Date) -> (protein: Int, fat: Int, carbs: Int) {
        let dateLogs = logs(for: date).filter { !$0.isAnalyzing }
        return (
            protein: dateLogs.reduce(0) { $0 + $1.protein },
            fat: dateLogs.reduce(0) { $0 + $1.fat },
            carbs: dateLogs.reduce(0) { $0 + $1.carbs }
        )
    }
    
    // MARK: - 特定日の詳細栄養素合計
    func detailedNutrients(for date: Date) -> (protein: Int, fat: Int, carbs: Int, sugar: Int, fiber: Int, sodium: Int) {
        let dateLogs = logs(for: date).filter { !$0.isAnalyzing }
        return (
            protein: dateLogs.reduce(0) { $0 + $1.protein },
            fat: dateLogs.reduce(0) { $0 + $1.fat },
            carbs: dateLogs.reduce(0) { $0 + $1.carbs },
            sugar: dateLogs.reduce(0) { $0 + $1.sugar },
            fiber: dateLogs.reduce(0) { $0 + $1.fiber },
            sodium: dateLogs.reduce(0) { $0 + $1.sodium }
        )
    }
    
    // MARK: - 特定日にログがあるか
    func hasLogs(for date: Date) -> Bool {
        !logs(for: date).isEmpty
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let mealLogAdded = Notification.Name("mealLogAdded")
    static let mealLogUpdated = Notification.Name("mealLogUpdated")
    static let mealLogDeleted = Notification.Name("mealLogDeleted")
    static let showHomeToast = Notification.Name("showHomeToast")
    static let dismissAllMealScreens = Notification.Name("dismissAllMealScreens")
    static let dismissAllExerciseScreens = Notification.Name("dismissAllExerciseScreens")
    static let dismissAllWeightScreens = Notification.Name("dismissAllWeightScreens")
    static let returnToManualEntry = Notification.Name("returnToManualEntry")
    static let weightLogAdded = Notification.Name("weightLogAdded")  // ✅ 追加
}
