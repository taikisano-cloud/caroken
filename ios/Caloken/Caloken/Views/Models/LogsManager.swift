import SwiftUI
import Combine

// MARK: - MealLogEntry
struct MealLogEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Int
    var protein: Int
    var fat: Int
    var carbs: Int
    var emoji: String
    var date: Date
    var imageData: Data?
    
    var image: UIImage? {
        get {
            if let data = imageData {
                return UIImage(data: data)
            }
            return nil
        }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Int = 0,
        fat: Int = 0,
        carbs: Int = 0,
        emoji: String = "🍽️",
        date: Date = Date(),
        image: UIImage? = nil
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.emoji = emoji
        self.date = date
        self.imageData = image?.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - MealLogsManager
class MealLogsManager: ObservableObject {
    static let shared = MealLogsManager()
    
    @Published var logs: [MealLogEntry] = []
    
    private let saveKey = "meal_logs"
    
    private init() {
        loadLogs()
    }
    
    // MARK: - CRUD Operations
    
    func addLog(_ log: MealLogEntry) {
        logs.append(log)
        logs.sort { $0.date > $1.date }
        saveLogs()
        notifyChange()
    }
    
    func updateLog(_ log: MealLogEntry) {
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = log
            saveLogs()
            notifyChange()
        }
    }
    
    func deleteLog(_ log: MealLogEntry) {
        logs.removeAll { $0.id == log.id }
        saveLogs()
        notifyChange()
    }
    
    func deleteLog(at offsets: IndexSet) {
        logs.remove(atOffsets: offsets)
        saveLogs()
        notifyChange()
    }
    
    // MARK: - Queries
    
    func logsForDate(_ date: Date) -> [MealLogEntry] {
        logs.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func todayLogs() -> [MealLogEntry] {
        logsForDate(Date())
    }
    
    func totalCaloriesForDate(_ date: Date) -> Int {
        logsForDate(date).reduce(0) { $0 + $1.calories }
    }
    
    func todayCalories() -> Int {
        totalCaloriesForDate(Date())
    }
    
    func todayProtein() -> Int {
        todayLogs().reduce(0) { $0 + $1.protein }
    }
    
    func todayFat() -> Int {
        todayLogs().reduce(0) { $0 + $1.fat }
    }
    
    func todayCarbs() -> Int {
        todayLogs().reduce(0) { $0 + $1.carbs }
    }
    
    // MARK: - Persistence
    
    private func saveLogs() {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let savedLogs = try? JSONDecoder().decode([MealLogEntry].self, from: data) {
            logs = savedLogs.sorted { $0.date > $1.date }
        }
    }
    
    // MARK: - Notification
    
    private func notifyChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .mealLogDidChange, object: nil)
        }
    }
}

// MARK: - ExerciseLogEntry
struct ExerciseLogEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var caloriesBurned: Int
    var duration: Int // minutes
    var emoji: String
    var date: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        caloriesBurned: Int,
        duration: Int = 0,
        emoji: String = "🏃",
        date: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.caloriesBurned = caloriesBurned
        self.duration = duration
        self.emoji = emoji
        self.date = date
    }
}

// MARK: - ExerciseLogsManager
class ExerciseLogsManager: ObservableObject {
    static let shared = ExerciseLogsManager()
    
    @Published var logs: [ExerciseLogEntry] = []
    
    private let saveKey = "exercise_logs"
    
    private init() {
        loadLogs()
    }
    
    // MARK: - CRUD Operations
    
    func addLog(_ log: ExerciseLogEntry) {
        logs.append(log)
        logs.sort { $0.date > $1.date }
        saveLogs()
        notifyChange()
    }
    
    func updateLog(_ log: ExerciseLogEntry) {
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = log
            saveLogs()
            notifyChange()
        }
    }
    
    func deleteLog(_ log: ExerciseLogEntry) {
        logs.removeAll { $0.id == log.id }
        saveLogs()
        notifyChange()
    }
    
    // MARK: - Queries
    
    func logsForDate(_ date: Date) -> [ExerciseLogEntry] {
        logs.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func todayLogs() -> [ExerciseLogEntry] {
        logsForDate(Date())
    }
    
    func totalBurnedForDate(_ date: Date) -> Int {
        logsForDate(date).reduce(0) { $0 + $1.caloriesBurned }
    }
    
    func todayBurned() -> Int {
        totalBurnedForDate(Date())
    }
    
    // MARK: - Persistence
    
    private func saveLogs() {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let savedLogs = try? JSONDecoder().decode([ExerciseLogEntry].self, from: data) {
            logs = savedLogs.sorted { $0.date > $1.date }
        }
    }
    
    // MARK: - Notification
    
    private func notifyChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .exerciseLogDidChange, object: nil)
        }
    }
}
