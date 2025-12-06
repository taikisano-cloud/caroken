import SwiftUI
import Combine

// MARK: - 保存済み運動アイテム（S51用）
struct SavedExerciseItem: Identifiable {
    let id: UUID
    let name: String
    let duration: Int
    let caloriesBurned: Int
    let icon: String
    
    init(id: UUID = UUID(), name: String, duration: Int, caloriesBurned: Int, icon: String) {
        self.id = id
        self.name = name
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.icon = icon
    }
}

// MARK: - 運動タイプ
enum ExerciseType: String, Codable, CaseIterable {
    case running = "running"
    case strength = "strength"
    case description = "description"
    case manualEntry = "manualEntry"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .running: return "有酸素運動"
        case .strength: return "無酸素運動"
        case .description: return "その他"
        case .manualEntry, .manual: return "手動入力"
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .strength: return "dumbbell.fill"
        case .description: return "figure.mixed.cardio"
        case .manualEntry, .manual: return "pencil"
        }
    }
    
    var color: Color {
        switch self {
        case .running: return .green
        case .strength: return .orange
        case .description: return .blue
        case .manualEntry, .manual: return .purple
        }
    }
}

// MARK: - 運動ログエントリー
struct ExerciseLogEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var duration: Int
    var caloriesBurned: Int
    var exerciseType: ExerciseType
    var intensity: String
    var date: Date
    var isAnalyzing: Bool
    
    init(id: UUID = UUID(), name: String, duration: Int, caloriesBurned: Int, exerciseType: ExerciseType, intensity: String = "", date: Date = Date(), isAnalyzing: Bool = false) {
        self.id = id
        self.name = name
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.exerciseType = exerciseType
        self.intensity = intensity
        self.date = date
        self.isAnalyzing = isAnalyzing
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var icon: String {
        exerciseType.icon
    }
}

// MARK: - 運動ログマネージャー
class ExerciseLogsManager: ObservableObject {
    static let shared = ExerciseLogsManager()
    
    @Published var allLogs: [ExerciseLogEntry] = []
    
    private let userDefaultsKey = "exerciseLogEntries_v3"
    
    private init() {
        loadLogs()
    }
    
    func logs(for date: Date) -> [ExerciseLogEntry] {
        let calendar = Calendar.current
        return allLogs
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
    
    func totalCalories(for date: Date) -> Int {
        logs(for: date).filter { !$0.isAnalyzing }.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    // S24_HomeViewとの互換性のため
    func totalCaloriesBurned(for date: Date) -> Int {
        totalCalories(for: date)
    }
    
    func caloriesByType(for date: Date) -> [ExerciseType: Int] {
        let dayLogs = logs(for: date).filter { !$0.isAnalyzing }
        var result: [ExerciseType: Int] = [:]
        for log in dayLogs {
            result[log.exerciseType, default: 0] += log.caloriesBurned
        }
        return result
    }
    
    func addLog(_ log: ExerciseLogEntry) {
        allLogs.insert(log, at: 0)
        saveLogs()
        NotificationCenter.default.post(name: .exerciseLogAdded, object: nil)
    }
    
    // 分析中のログを追加
    func addAnalyzingLog(name: String, duration: Int, exerciseType: ExerciseType = .description, intensity: String = "", for date: Date) -> UUID {
        let id = UUID()
        let log = ExerciseLogEntry(
            id: id,
            name: name,
            duration: duration,
            caloriesBurned: 0,
            exerciseType: exerciseType,
            intensity: intensity,
            date: date,
            isAnalyzing: true
        )
        allLogs.insert(log, at: 0)
        saveLogs()
        NotificationCenter.default.post(name: .exerciseLogAdded, object: nil)
        return id
    }
    
    // 分析完了
    func completeAnalyzing(id: UUID, caloriesBurned: Int) {
        if let index = allLogs.firstIndex(where: { $0.id == id }) {
            allLogs[index].caloriesBurned = caloriesBurned
            allLogs[index].isAnalyzing = false
            saveLogs()
            NotificationCenter.default.post(name: .exerciseLogUpdated, object: nil)
        }
    }
    
    func updateLog(_ log: ExerciseLogEntry) {
        if let index = allLogs.firstIndex(where: { $0.id == log.id }) {
            allLogs[index] = log
            saveLogs()
        }
    }
    
    func removeLog(_ log: ExerciseLogEntry) {
        allLogs.removeAll { $0.id == log.id }
        saveLogs()
    }
    
    func removeLog(id: UUID) {
        allLogs.removeAll { $0.id == id }
        saveLogs()
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
           let decoded = try? JSONDecoder().decode([ExerciseLogEntry].self, from: data) {
            allLogs = decoded
        }
    }
}

// MARK: - 保存済み運動のモデル
struct SavedExercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let duration: Int
    let caloriesBurned: Int
    let exerciseType: ExerciseType
    let intensity: String
    let savedAt: Date
    
    init(id: UUID = UUID(), name: String, duration: Int, caloriesBurned: Int, exerciseType: ExerciseType, intensity: String = "", savedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.exerciseType = exerciseType
        self.intensity = intensity
        self.savedAt = savedAt
    }
    
    var icon: String {
        exerciseType.icon
    }
    
    var color: Color {
        exerciseType.color
    }
}

// MARK: - 保存済み運動マネージャー
class SavedExercisesManager: ObservableObject {
    static let shared = SavedExercisesManager()
    
    @Published var savedExercises: [SavedExercise] = []
    
    private let userDefaultsKey = "savedExercises_v1"
    
    private init() {
        loadExercises()
    }
    
    func addExercise(_ exercise: SavedExercise) {
        objectWillChange.send()
        savedExercises.insert(exercise, at: 0)
        saveExercises()
        NotificationCenter.default.post(name: .exerciseAddedToSaved, object: nil)
    }
    
    func removeExercise(_ exercise: SavedExercise) {
        objectWillChange.send()
        savedExercises.removeAll { $0.id == exercise.id }
        saveExercises()
    }
    
    func hasExercise(named name: String) -> Bool {
        savedExercises.contains { $0.name == name }
    }
    
    private func saveExercises() {
        if let encoded = try? JSONEncoder().encode(savedExercises) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadExercises() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([SavedExercise].self, from: data) {
            savedExercises = decoded
        }
    }
}
