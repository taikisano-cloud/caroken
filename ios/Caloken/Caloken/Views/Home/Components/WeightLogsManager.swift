import SwiftUI
import Combine

// MARK: - 体重ログエントリ
struct WeightLogEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weight: Double
    
    init(id: UUID = UUID(), date: Date = Date(), weight: Double) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.weight = weight
    }
}

// MARK: - 体重ログマネージャー
class WeightLogsManager: ObservableObject {
    static let shared = WeightLogsManager()
    
    @Published var allLogs: [WeightLogEntry] = []
    
    // 目標関連
    @Published var targetWeight: Double = 68.0
    @Published var startWeight: Double = 75.0
    @Published var targetDate: Date = Calendar.current.date(byAdding: .month, value: 2, to: Date())!
    @Published var hasDeadline: Bool = true
    
    private let logsKey = "weightLogs_v1"
    private let settingsKey = "weightSettings_v1"
    
    private init() {
        loadLogs()
        loadSettings()
    }
    
    // 最新の体重を取得
    var currentWeight: Double {
        allLogs.sorted { $0.date > $1.date }.first?.weight ?? startWeight
    }
    
    // 指定日の体重を取得
    func weight(for date: Date) -> Double? {
        let calendar = Calendar.current
        return allLogs.first { calendar.isDate($0.date, inSameDayAs: date) }?.weight
    }
    
    // 体重を記録
    func addLog(_ weight: Double, for date: Date = Date()) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // 同じ日のログがあれば更新
        if let index = allLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: startOfDay) }) {
            allLogs[index] = WeightLogEntry(id: allLogs[index].id, date: startOfDay, weight: weight)
        } else {
            allLogs.append(WeightLogEntry(date: startOfDay, weight: weight))
        }
        
        saveLogs()
        
        // 通知を送信
        NotificationCenter.default.post(name: .weightLogAdded, object: nil)
    }
    
    // 体重ログを削除
    func removeLog(_ log: WeightLogEntry) {
        allLogs.removeAll { $0.id == log.id }
        saveLogs()
    }
    
    // 期間内のログを取得
    func logs(for period: ProgressPeriod) -> [WeightLogEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        case .all:
            return allLogs.sorted { $0.date < $1.date }
        }
        
        return allLogs.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
    }
    
    // 目標設定を更新
    func updateGoal(targetWeight: Double, startWeight: Double, targetDate: Date, hasDeadline: Bool) {
        self.targetWeight = targetWeight
        self.startWeight = startWeight
        self.targetDate = targetDate
        self.hasDeadline = hasDeadline
        saveSettings()
    }
    
    // 進捗率を計算
    var progressPercentage: Double {
        let totalLoss = startWeight - targetWeight
        guard totalLoss > 0 else { return 0 }
        let currentLoss = startWeight - currentWeight
        return min(max(currentLoss / totalLoss * 100, 0), 100)
    }
    
    // 残り日数
    var daysRemaining: Int {
        guard hasDeadline else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return max(components.day ?? 0, 0)
    }
    
    // MARK: - 永続化
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(encoded, forKey: logsKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([WeightLogEntry].self, from: data) {
            allLogs = decoded
        }
    }
    
    private func saveSettings() {
        let settings: [String: Any] = [
            "targetWeight": targetWeight,
            "startWeight": startWeight,
            "targetDate": targetDate.timeIntervalSince1970,
            "hasDeadline": hasDeadline
        ]
        UserDefaults.standard.set(settings, forKey: settingsKey)
    }
    
    private func loadSettings() {
        if let settings = UserDefaults.standard.dictionary(forKey: settingsKey) {
            targetWeight = settings["targetWeight"] as? Double ?? 68.0
            startWeight = settings["startWeight"] as? Double ?? 75.0
            if let timestamp = settings["targetDate"] as? TimeInterval {
                targetDate = Date(timeIntervalSince1970: timestamp)
            }
            hasDeadline = settings["hasDeadline"] as? Bool ?? true
        }
    }
}

// MARK: - 期間タイプ（共通で使用）
enum ProgressPeriod: String, CaseIterable {
    case week = "1週間"
    case sixMonths = "6ヶ月"
    case year = "1年"
    case all = "ALL"
}
