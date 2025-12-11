import SwiftUI
import Combine

// MARK: - 運動種別
enum ExerciseType: String, Codable, CaseIterable {
    case running = "running"
    case walking = "walking"
    case cycling = "cycling"
    case swimming = "swimming"
    case gym = "gym"
    case yoga = "yoga"
    case manual = "manual"
    case strength = "strength"      // ✅ 追加
    case description = "description" // ✅ 追加
    
    var displayName: String {
        switch self {
        case .running: return "ランニング"
        case .walking: return "ウォーキング"
        case .cycling: return "サイクリング"
        case .swimming: return "水泳"
        case .gym: return "ジム"
        case .yoga: return "ヨガ"
        case .manual: return "手動入力"
        case .strength: return "筋トレ"
        case .description: return "その他"
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .gym: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        case .manual: return "flame.fill"
        case .strength: return "dumbbell.fill"
        case .description: return "figure.mixed.cardio"
        }
    }
    
    var caloriesPerMinute: Double {
        switch self {
        case .running: return 10.0
        case .walking: return 4.0
        case .cycling: return 7.0
        case .swimming: return 8.0
        case .gym: return 6.0
        case .yoga: return 3.0
        case .manual: return 5.0
        case .strength: return 5.0
        case .description: return 5.0
        }
    }
}

// MARK: - 運動ログエントリー
struct ExerciseLogEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var duration: Int  // 分
    var caloriesBurned: Int
    var exerciseType: ExerciseType
    var intensity: String       // ✅ 追加
    var date: Date
    var time: Date
    var isAnalyzing: Bool
    var isAnalyzingError: Bool  // ✅ 追加
    var hasTimedOut: Bool       // ✅ 追加
    
    // ✅ iconはcomputed property
    var icon: String {
        exerciseType.icon
    }
    
    // ✅ 時刻文字列
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    init(
        id: UUID = UUID(),
        name: String = "",
        duration: Int = 0,
        caloriesBurned: Int = 0,
        exerciseType: ExerciseType = .manual,
        intensity: String = "",
        date: Date = Date(),
        time: Date? = nil,
        isAnalyzing: Bool = false,
        isAnalyzingError: Bool = false,
        hasTimedOut: Bool = false
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.exerciseType = exerciseType
        self.intensity = intensity
        self.date = date
        self.time = time ?? date
        self.isAnalyzing = isAnalyzing
        self.isAnalyzingError = isAnalyzingError
        self.hasTimedOut = hasTimedOut
    }
    
    // ✅ Codable - iconはencode/decodeしない
    private enum CodingKeys: String, CodingKey {
        case id, name, duration, caloriesBurned, exerciseType, intensity, date, time
        case isAnalyzing, isAnalyzingError, hasTimedOut
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        duration = try container.decode(Int.self, forKey: .duration)
        caloriesBurned = try container.decode(Int.self, forKey: .caloriesBurned)
        exerciseType = try container.decode(ExerciseType.self, forKey: .exerciseType)
        intensity = try container.decodeIfPresent(String.self, forKey: .intensity) ?? ""
        date = try container.decode(Date.self, forKey: .date)
        time = try container.decodeIfPresent(Date.self, forKey: .time) ?? date
        isAnalyzing = try container.decodeIfPresent(Bool.self, forKey: .isAnalyzing) ?? false
        isAnalyzingError = try container.decodeIfPresent(Bool.self, forKey: .isAnalyzingError) ?? false
        hasTimedOut = try container.decodeIfPresent(Bool.self, forKey: .hasTimedOut) ?? false
    }
}

// MARK: - 運動ログマネージャー
final class ExerciseLogsManager: ObservableObject {
    static let shared = ExerciseLogsManager()
    
    @Published private(set) var allLogs: [ExerciseLogEntry] = []
    
    private let userDefaultsKey = "exerciseLogs"
    
    private init() {
        loadLogs()
    }
    
    // MARK: - 日付でフィルタリング
    func logs(for date: Date) -> [ExerciseLogEntry] {
        let calendar = Calendar.current
        return allLogs.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.time > $1.time }
    }
    
    // MARK: - ログ追加
    func addLog(_ log: ExerciseLogEntry) {
        allLogs.append(log)
        saveLogs()
    }
    
    // MARK: - 分析中ログ追加
    func addAnalyzingLog(name: String, duration: Int, for date: Date) -> UUID {
        let log = ExerciseLogEntry(
            name: name,
            duration: duration,
            caloriesBurned: 0,
            exerciseType: .manual,
            date: date,
            time: Date(),
            isAnalyzing: true
        )
        allLogs.append(log)
        saveLogs()
        return log.id
    }
    
    // MARK: - 分析完了
    func completeAnalyzing(id: UUID, caloriesBurned: Int) {
        if let index = allLogs.firstIndex(where: { $0.id == id }) {
            allLogs[index].caloriesBurned = caloriesBurned
            allLogs[index].isAnalyzing = false
            saveLogs()
        }
    }
    
    // MARK: - ログ更新
    func updateLog(_ log: ExerciseLogEntry) {
        if let index = allLogs.firstIndex(where: { $0.id == log.id }) {
            allLogs[index] = log
            saveLogs()
        }
    }
    
    // MARK: - ログ削除
    func removeLog(id: UUID) {
        allLogs.removeAll { $0.id == id }
        saveLogs()
    }
    
    // MARK: - 特定日の消費カロリー合計
    func totalCaloriesBurned(for date: Date) -> Int {
        logs(for: date).filter { !$0.isAnalyzing }.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    // MARK: - 永続化
    private func saveLogs() {
        if let data = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let logs = try? JSONDecoder().decode([ExerciseLogEntry].self, from: data) {
            allLogs = logs
        }
    }
}

// MARK: - 保存済み運動アイテム（S51_ExerciseDetailView用）
struct SavedExerciseItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var duration: Int
    var caloriesBurned: Int
    var exerciseType: ExerciseType
    var intensity: String
    
    init(
        id: UUID = UUID(),
        name: String = "",
        duration: Int = 30,
        caloriesBurned: Int = 150,
        exerciseType: ExerciseType = .manual,
        intensity: String = ""
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.exerciseType = exerciseType
        self.intensity = intensity
    }
}

// MARK: - 保存済み運動（SavedExercisesManager用）
struct SavedExercise: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var duration: Int
    var caloriesBurned: Int
    var exerciseType: ExerciseType
    var intensity: String
    
    init(
        id: UUID = UUID(),
        name: String = "",
        duration: Int = 30,
        caloriesBurned: Int = 150,
        exerciseType: ExerciseType = .manual,
        intensity: String = ""
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.exerciseType = exerciseType
        self.intensity = intensity
    }
}

// MARK: - 保存済み運動マネージャー
final class SavedExercisesManager: ObservableObject {
    static let shared = SavedExercisesManager()
    
    @Published var savedExercises: [SavedExercise] = []
    
    private let userDefaultsKey = "savedExercises"
    
    private init() {
        loadExercises()
    }
    
    func addExercise(_ exercise: SavedExercise) {
        savedExercises.append(exercise)
        saveExercises()
    }
    
    func removeExercise(id: UUID) {
        savedExercises.removeAll { $0.id == id }
        saveExercises()
    }
    
    func updateExercise(_ exercise: SavedExercise) {
        if let index = savedExercises.firstIndex(where: { $0.id == exercise.id }) {
            savedExercises[index] = exercise
            saveExercises()
        }
    }
    
    private func saveExercises() {
        if let data = try? JSONEncoder().encode(savedExercises) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadExercises() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let exercises = try? JSONDecoder().decode([SavedExercise].self, from: data) {
            savedExercises = exercises
        }
    }
}
