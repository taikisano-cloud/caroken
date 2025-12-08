import SwiftUI
import Combine

// MARK: - Home Advice Manager
class HomeAdviceManager: ObservableObject {
    static let shared = HomeAdviceManager()
    
    @Published var currentAdvice: String = "今日も一緒にがんばろうにゃ！🐱"
    @Published var isLoadingAdvice: Bool = false
    
    private var lastUpdateTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // アプリ起動時にアドバイスを取得
        loadCachedAdvice()
    }
    
    // MARK: - Public Methods
    
    func refreshAdvice() {
        // 頻繁な更新を防止（最低15秒間隔）
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < 15 {
            return
        }
        
        Task {
            await fetchAdviceFromAPI()
        }
    }
    
    func forceRefreshAdvice() {
        lastUpdateTime = nil
        Task {
            await fetchAdviceFromAPI()
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func fetchAdviceFromAPI() async {
        isLoadingAdvice = true
        
        let todayStats = getTodayStats()
        
        do {
            let advice = try await NetworkManager.shared.getHomeAdvice(
                todayCalories: todayStats.calories,
                goalCalories: todayStats.goalCalories,
                todayProtein: todayStats.protein,
                todayFat: todayStats.fat,
                todayCarbs: todayStats.carbs,
                todayMeals: todayStats.mealsDescription,
                mealCount: todayStats.mealCount
            )
            
            currentAdvice = advice
            lastUpdateTime = Date()
            cacheAdvice(advice)
            
            print("✅ Advice updated: \(advice)")
            
        } catch {
            print("❌ Failed to get advice: \(error)")
            // エラー時はフォールバックアドバイスを使用
            currentAdvice = getFallbackAdvice(stats: todayStats)
        }
        
        isLoadingAdvice = false
    }
    
    private func getTodayStats() -> TodayStats {
        // MealLogsManagerから今日のログを取得
        let todayLogs = MealLogsManager.shared.logsForDate(Date())
        
        let calories = MealLogsManager.shared.totalCalories(for: Date())
        let nutrients = MealLogsManager.shared.totalNutrients(for: Date())
        let mealsDescription = todayLogs.map { "\($0.name)(\($0.calories)kcal)" }.joined(separator: ", ")
        
        // 目標カロリーはUserProfileManagerから取得
        let goalCalories = UserProfileManager.shared.calorieGoal
        
        return TodayStats(
            calories: calories,
            goalCalories: goalCalories,
            protein: nutrients.protein,
            fat: nutrients.fat,
            carbs: nutrients.carbs,
            mealsDescription: mealsDescription,
            mealCount: todayLogs.count
        )
    }
    
    // APIエラー時のフォールバックアドバイス
    private func getFallbackAdvice(stats: TodayStats) -> String {
        if stats.calories == 0 {
            return "今日はまだ何も食べてないにゃ🐱\n何か記録してみよう！"
        } else if stats.protein < 50 {
            return "今日はタンパク質が不足気味だにゃ🐱\n夕食でお肉か魚を食べるといいかも！"
        } else if stats.calories > stats.goalCalories {
            return "今日はカロリーオーバーだにゃ😅\n明日は少し控えめにしよう！"
        } else {
            return "いい感じだにゃ🐱\nバランスよく食べられてるよ！この調子✨"
        }
    }
    
    private func cacheAdvice(_ advice: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH"
        let key = "home_advice_\(formatter.string(from: Date()))"
        UserDefaults.standard.set(advice, forKey: key)
    }
    
    private func loadCachedAdvice() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH"
        let key = "home_advice_\(formatter.string(from: Date()))"
        
        if let cached = UserDefaults.standard.string(forKey: key) {
            currentAdvice = cached
        }
    }
}

// MARK: - Today Stats
private struct TodayStats {
    let calories: Int
    let goalCalories: Int
    let protein: Int
    let fat: Int
    let carbs: Int
    let mealsDescription: String
    let mealCount: Int
}
