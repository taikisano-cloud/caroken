import SwiftUI
import Combine

// MARK: - 水分ログのモデル
struct WaterLogEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var amount: Int  // ml単位
    
    init(id: UUID = UUID(), date: Date = Date(), amount: Int = 0) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.amount = amount
    }
}

// MARK: - 水分ログマネージャー
class WaterLogsManager: ObservableObject {
    static let shared = WaterLogsManager()
    
    @Published var allLogs: [WaterLogEntry] = []
    
    private let userDefaultsKey = "waterLogEntries_v1"
    
    private init() {
        loadLogs()
    }
    
    // 指定日の水分量を取得（ml）
    func waterAmount(for date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return allLogs.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }?.amount ?? 0
    }
    
    // 指定日の水分量を設定（ml）
    func setWaterAmount(_ amount: Int, for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if let index = allLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: startOfDay) }) {
            allLogs[index].amount = amount
        } else {
            let newEntry = WaterLogEntry(date: startOfDay, amount: amount)
            allLogs.append(newEntry)
        }
        
        saveLogs()
        print("💧 水分量更新: \(amount)ml for \(startOfDay)")
    }
    
    // 指定日の水分量を増加（ml）
    func addWater(_ amount: Int, for date: Date) {
        let currentAmount = waterAmount(for: date)
        setWaterAmount(currentAmount + amount, for: date)
    }
    
    // 指定日の水分量を減少（ml）
    func removeWater(_ amount: Int, for date: Date) {
        let currentAmount = waterAmount(for: date)
        let newAmount = max(0, currentAmount - amount)
        setWaterAmount(newAmount, for: date)
    }
    
    // グラス数を取得（250ml = 1グラス）
    func glassCount(for date: Date) -> Int {
        return waterAmount(for: date) / 250
    }
    
    // グラス数を設定
    func setGlassCount(_ count: Int, for date: Date) {
        setWaterAmount(count * 250, for: date)
    }
    
    // 目標達成率を取得（目標: 2000ml）
    func progress(for date: Date, goal: Int = 2000) -> Double {
        let amount = waterAmount(for: date)
        return min(Double(amount) / Double(goal), 1.0)
    }
    
    private func saveLogs() {
        // 古いログを削除（30日以上前のものを削除）
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        allLogs = allLogs.filter { $0.date >= thirtyDaysAgo }
        
        if let encoded = try? JSONEncoder().encode(allLogs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([WaterLogEntry].self, from: data) {
            allLogs = decoded
            print("📂 水分ログ読み込み: \(allLogs.count)件")
        }
    }
}
