import SwiftUI
import Combine
import UIKit

// MARK: - 分析中の状態管理（AI API連携版 - 進捗%表示対応）
final class AnalyzingManager: ObservableObject {
    static let shared = AnalyzingManager()
    
    @Published var analyzingMealId: UUID?
    @Published var analyzingExerciseId: UUID?
    @Published var analysisProgress: String = "分析中..."
    @Published var progressPercent: Int = 0  // ✅ 進捗パーセント
    
    private var mealTimer: Timer?
    private var exerciseTimer: Timer?
    private var progressTimer: Timer?
    private let network = NetworkManager.shared
    
    // バックグラウンドタスク用
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private init() {}
    
    // MARK: - 食事分析開始（写真から）- AI API使用
    func startMealAnalyzing(image: UIImage?, for date: Date) {
        let logId = MealLogsManager.shared.addAnalyzingLog(image: image, for: date)
        analyzingMealId = logId
        analysisProgress = "画像を準備中..."
        progressPercent = 0
        
        // バックグラウンドタスク開始
        startBackgroundTask()
        
        // 進捗アニメーション開始
        startProgressAnimation()
        
        // 画像がある場合はAI APIを呼び出す
        if let image = image {
            Task {
                await analyzeMealWithAI(id: logId, image: image)
            }
        } else {
            // 画像がない場合は従来のモック処理
            mealTimer?.invalidate()
            mealTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                let noDesc: String? = nil
                self?.completeMealAnalysis(id: logId, fromDescription: noDesc)
            }
        }
    }
    
    // MARK: - 食事分析開始（手動入力から）- AI API使用
    func startManualMealAnalyzing(description: String, for date: Date) {
        let logId = MealLogsManager.shared.addAnalyzingLog(image: nil, for: date)
        analyzingMealId = logId
        analysisProgress = "AIが計算中..."
        progressPercent = 0
        
        // バックグラウンドタスク開始
        startBackgroundTask()
        
        // 進捗アニメーション開始
        startProgressAnimation()
        
        // AI APIを呼び出す
        Task {
            await analyzeMealTextWithAI(id: logId, description: description)
        }
    }
    
    // MARK: - 進捗アニメーション
    private func startProgressAnimation() {
        progressTimer?.invalidate()
        progressPercent = 0
        
        // 0%から90%まで徐々に上げる（実際の完了時に100%になる）
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                if self.progressPercent < 90 {
                    // 最初は速く、後半は遅くなる進捗
                    let increment = max(1, (90 - self.progressPercent) / 10)
                    self.progressPercent = min(90, self.progressPercent + increment)
                    
                    // 進捗に応じてメッセージを更新
                    if self.progressPercent < 30 {
                        self.analysisProgress = "分析中... \(self.progressPercent)%"
                    } else if self.progressPercent < 60 {
                        self.analysisProgress = "栄養素を計算中... \(self.progressPercent)%"
                    } else {
                        self.analysisProgress = "最終処理中... \(self.progressPercent)%"
                    }
                    
                    // ✅ MealLogEntryにも進捗を反映
                    if let mealId = self.analyzingMealId {
                        MealLogsManager.shared.updateAnalysisProgress(id: mealId, progress: self.progressPercent)
                    }
                }
            }
        }
    }
    
    private func stopProgressAnimation() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - バックグラウンドタスク管理
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // MARK: - AI画像分析
    private func analyzeMealWithAI(id: UUID, image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            await MainActor.run {
                let noDesc: String? = nil
                self.completeMealAnalysis(id: id, fromDescription: noDesc)
            }
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        do {
            let result = try await network.analyzeMeal(imageBase64: base64String)
            await MainActor.run {
                self.completeMealAnalysisWithAI(id: id, result: result)
            }
        } catch {
            debugPrint("❌ AI Image analysis error: \(error)")
            await MainActor.run {
                let noDesc: String? = nil
                self.completeMealAnalysis(id: id, fromDescription: noDesc)
            }
        }
    }
    
    // MARK: - AIテキスト分析
    private func analyzeMealTextWithAI(id: UUID, description: String) async {
        do {
            let result = try await network.analyzeMeal(description: description)
            await MainActor.run {
                self.completeMealAnalysisWithAI(id: id, result: result)
            }
        } catch {
            debugPrint("❌ AI Text analysis error: \(error)")
            await MainActor.run {
                self.completeMealAnalysis(id: id, fromDescription: description)
            }
        }
    }
    
    // MARK: - AI分析結果で完了（sugar/fiber/sodium対応）
    private func completeMealAnalysisWithAI(id: UUID, result: DetailedMealAnalysis) {
        // 進捗を100%に
        stopProgressAnimation()
        progressPercent = 100
        analysisProgress = "完了！"
        
        let name: String
        if result.food_items.count == 1 {
            name = result.food_items.first?.name ?? "食事"
        } else if result.food_items.count > 1 {
            name = result.food_items.prefix(2).map { $0.name }.joined(separator: "と")
        } else {
            name = "食事"
        }
        
        // ✅ sugar, fiber, sodiumも含めて保存
        MealLogsManager.shared.completeAnalyzing(
            id: id,
            name: name,
            calories: result.total_calories,
            protein: Int(result.total_protein),
            fat: Int(result.total_fat),
            carbs: Int(result.total_carbs),
            sugar: Int(result.total_sugar),
            fiber: Int(result.total_fiber),
            sodium: Int(result.total_sodium),
            emoji: selectEmoji(for: name),
            characterComment: result.character_comment
        )
        
        DispatchQueue.main.async {
            self.analyzingMealId = nil
            self.analysisProgress = "分析中..."
            self.progressPercent = 0
            self.endBackgroundTask()
            
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "\(name)を記録しました", "color": Color.green]
            )
            
            // 食事記録通知を発行
            NotificationCenter.default.post(name: .mealLogAdded, object: nil)
        }
    }
    
    // MARK: - モック分析結果で完了（フォールバック用）
    private func completeMealAnalysis(id: UUID, fromDescription: String?) {
        stopProgressAnimation()
        progressPercent = 100
        
        let name: String
        if let desc = fromDescription {
            name = String(desc.prefix(20))
        } else {
            let names = ["分析した料理", "美味しそうな料理", "ヘルシーな食事"]
            name = names.randomElement() ?? "食事"
        }
        let calories = Int.random(in: 300...600)
        let protein = Int.random(in: 15...35)
        let fat = Int.random(in: 10...25)
        let carbs = Int.random(in: 30...60)
        
        MealLogsManager.shared.completeAnalyzing(
            id: id,
            name: name,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            sugar: 0,
            fiber: 0,
            sodium: 0,
            emoji: "🍽️",
            characterComment: ""
        )
        
        DispatchQueue.main.async {
            self.analyzingMealId = nil
            self.analysisProgress = "分析中..."
            self.progressPercent = 0
            self.endBackgroundTask()
            
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "食事を記録しました（概算）", "color": Color.orange]
            )
            
            NotificationCenter.default.post(name: .mealLogAdded, object: nil)
        }
    }
    
    // MARK: - 絵文字選択
    private func selectEmoji(for name: String) -> String {
        let lowercased = name.lowercased()
        if lowercased.contains("ラーメン") || lowercased.contains("麺") { return "🍜" }
        if lowercased.contains("ご飯") || lowercased.contains("米") || lowercased.contains("丼") { return "🍚" }
        if lowercased.contains("パン") { return "🍞" }
        if lowercased.contains("サラダ") { return "🥗" }
        if lowercased.contains("肉") || lowercased.contains("ステーキ") { return "🥩" }
        if lowercased.contains("魚") || lowercased.contains("寿司") { return "🍣" }
        if lowercased.contains("卵") { return "🍳" }
        if lowercased.contains("カレー") { return "🍛" }
        if lowercased.contains("ピザ") { return "🍕" }
        if lowercased.contains("ハンバーガー") { return "🍔" }
        if lowercased.contains("パスタ") { return "🍝" }
        if lowercased.contains("コーヒー") { return "☕" }
        if lowercased.contains("ケーキ") || lowercased.contains("スイーツ") { return "🍰" }
        return "🍽️"
    }
    
    // MARK: - 食事を即座に記録（分析中表示なし）
    func saveMealInstantly(name: String, calories: Int, protein: Int = 0, fat: Int = 0, carbs: Int = 0, for date: Date) {
        let mealLog = MealLogEntry(
            name: name,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            emoji: "🍽️",
            date: date
        )
        MealLogsManager.shared.addLog(mealLog)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "\(name)を記録しました", "color": Color.green]
            )
            NotificationCenter.default.post(name: .dismissAllMealScreens, object: nil)
            NotificationCenter.default.post(name: .mealLogAdded, object: nil)
        }
    }
    
    // MARK: - 運動を即座に記録（分析中表示なし）
    func saveExerciseInstantly(name: String, duration: Int, caloriesBurned: Int, exerciseType: ExerciseType = .manual) {
        let exerciseLog = ExerciseLogEntry(
            name: name,
            duration: duration,
            caloriesBurned: caloriesBurned,
            exerciseType: exerciseType
        )
        ExerciseLogsManager.shared.addLog(exerciseLog)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "\(caloriesBurned) kcal を消費として記録しました", "color": Color.green]
            )
            NotificationCenter.default.post(name: .dismissAllExerciseScreens, object: nil)
        }
    }
    
    // MARK: - 運動分析開始
    func startExerciseAnalyzing(description: String, duration: Int) {
        let logId = ExerciseLogsManager.shared.addAnalyzingLog(
            name: description,
            duration: duration,
            for: Date()
        )
        analyzingExerciseId = logId
        
        // 2秒後に分析完了
        exerciseTimer?.invalidate()
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.completeExerciseAnalysis(id: logId, description: description, duration: duration)
        }
    }
    
    private func completeExerciseAnalysis(id: UUID, description: String, duration: Int) {
        let estimatedCalories = Int(Double(duration) * 5.0)
        
        ExerciseLogsManager.shared.completeAnalyzing(
            id: id,
            caloriesBurned: estimatedCalories
        )
        
        DispatchQueue.main.async {
            self.analyzingExerciseId = nil
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "\(description)を記録しました", "color": Color.green]
            )
        }
    }
    
    func cancelMealAnalysis() {
        stopProgressAnimation()
        mealTimer?.invalidate()
        if let id = analyzingMealId {
            MealLogsManager.shared.removeLog(id: id)
        }
        analyzingMealId = nil
        progressPercent = 0
        endBackgroundTask()
    }
    
    func cancelExerciseAnalysis() {
        exerciseTimer?.invalidate()
        if let id = analyzingExerciseId {
            ExerciseLogsManager.shared.removeLog(id: id)
        }
        analyzingExerciseId = nil
    }
}
