import SwiftUI
import Combine

// MARK: - ユーザープロフィールマネージャー
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    // 身体情報
    @Published var height: Int = 170  // cm
    @Published var gender: String = "Male"
    @Published var birthDate: Date = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
    
    // 目標設定
    @Published var goal: String = "減量"  // 減量/維持/増量
    @Published var exerciseFrequency: String = "たまに"  // めったにしない/たまに/よくする
    @Published var targetWeight: Int = 65  // kg
    @Published var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    
    // 栄養目標
    @Published var calorieGoal: Int = 2000
    @Published var carbGoal: Int = 250
    @Published var proteinGoal: Int = 120
    @Published var fatGoal: Int = 65
    @Published var sugarGoal: Int = 25
    @Published var fiberGoal: Int = 28
    @Published var sodiumGoal: Int = 2000
    
    // オンボーディング完了フラグ
    @Published var hasCompletedOnboarding: Bool = false
    
    private let profileKey = "userProfile_v1"
    private let nutritionKey = "nutritionGoals_v1"
    private let goalKey = "userGoals_v1"
    private let onboardingKey = "hasCompletedOnboarding"
    
    private init() {
        loadProfile()
        loadNutritionGoals()
        loadGoals()
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
    }
    
    // 現在の体重（WeightLogsManagerから取得）
    var currentWeight: Double {
        WeightLogsManager.shared.currentWeight
    }
    
    // BMI計算
    var bmi: Double {
        let heightInMeters = Double(height) / 100.0
        guard heightInMeters > 0 else { return 0 }
        return currentWeight / (heightInMeters * heightInMeters)
    }
    
    // BMIステータス
    var bmiStatus: String {
        if bmi < 18.5 { return "低体重" }
        else if bmi < 25 { return "適正" }
        else if bmi < 30 { return "過体重" }
        else { return "肥満" }
    }
    
    // 年齢計算
    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year], from: birthDate, to: now)
        return components.year ?? 0
    }
    
    // 目標達成までの日数
    var daysUntilTarget: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return max(0, components.day ?? 0)
    }
    
    // MARK: - 永続化
    
    func saveProfile() {
        let profile: [String: Any] = [
            "height": height,
            "gender": gender,
            "birthDate": birthDate.timeIntervalSince1970
        ]
        UserDefaults.standard.set(profile, forKey: profileKey)
        
        // 変更を通知
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
        print("👤 プロフィール保存: 身長\(height)cm")
    }
    
    private func loadProfile() {
        if let profile = UserDefaults.standard.dictionary(forKey: profileKey) {
            height = profile["height"] as? Int ?? 170
            gender = profile["gender"] as? String ?? "Male"
            if let timestamp = profile["birthDate"] as? TimeInterval {
                birthDate = Date(timeIntervalSince1970: timestamp)
            }
            print("📂 プロフィール読み込み: 身長\(height)cm")
        }
    }
    
    func saveNutritionGoals() {
        let goals: [String: Any] = [
            "calorieGoal": calorieGoal,
            "carbGoal": carbGoal,
            "proteinGoal": proteinGoal,
            "fatGoal": fatGoal,
            "sugarGoal": sugarGoal,
            "fiberGoal": fiberGoal,
            "sodiumGoal": sodiumGoal
        ]
        UserDefaults.standard.set(goals, forKey: nutritionKey)
        
        // 変更を通知
        NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
        print("🎯 栄養目標保存: \(calorieGoal)kcal")
    }
    
    private func loadNutritionGoals() {
        if let goals = UserDefaults.standard.dictionary(forKey: nutritionKey) {
            calorieGoal = goals["calorieGoal"] as? Int ?? 2000
            carbGoal = goals["carbGoal"] as? Int ?? 250
            proteinGoal = goals["proteinGoal"] as? Int ?? 120
            fatGoal = goals["fatGoal"] as? Int ?? 65
            sugarGoal = goals["sugarGoal"] as? Int ?? 25
            fiberGoal = goals["fiberGoal"] as? Int ?? 28
            sodiumGoal = goals["sodiumGoal"] as? Int ?? 2000
            print("📂 栄養目標読み込み: \(calorieGoal)kcal")
        }
    }
    
    func saveGoals() {
        let goals: [String: Any] = [
            "goal": goal,
            "exerciseFrequency": exerciseFrequency,
            "targetWeight": targetWeight,
            "targetDate": targetDate.timeIntervalSince1970
        ]
        UserDefaults.standard.set(goals, forKey: goalKey)
        print("🎯 目標保存: \(targetWeight)kg, \(goal)")
    }
    
    private func loadGoals() {
        if let goals = UserDefaults.standard.dictionary(forKey: goalKey) {
            goal = goals["goal"] as? String ?? "減量"
            exerciseFrequency = goals["exerciseFrequency"] as? String ?? "たまに"
            targetWeight = goals["targetWeight"] as? Int ?? 65
            if let timestamp = goals["targetDate"] as? TimeInterval {
                targetDate = Date(timeIntervalSince1970: timestamp)
            }
            print("📂 目標読み込み: \(targetWeight)kg")
        }
    }
    
    // オンボーディング完了
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
        
        // 全データを保存
        saveProfile()
        saveNutritionGoals()
        saveGoals()
        
        print("✅ オンボーディング完了")
    }
    
    // オンボーディングからのデータ設定
    func setOnboardingData(
        goal: String,
        exerciseFrequency: String,
        gender: String,
        birthDate: Date,
        currentWeight: Int,
        height: Int,
        targetWeight: Int,
        targetDate: Date,
        calories: Int,
        carbs: Int,
        protein: Int,
        fat: Int
    ) {
        self.goal = goal
        self.exerciseFrequency = exerciseFrequency
        self.gender = gender
        self.birthDate = birthDate
        self.height = height
        self.targetWeight = targetWeight
        self.targetDate = targetDate
        self.calorieGoal = calories
        self.carbGoal = carbs
        self.proteinGoal = protein
        self.fatGoal = fat
        
        // 体重も記録
        WeightLogsManager.shared.addLog(Double(currentWeight))
        
        print("📝 オンボーディングデータ設定: 目標\(targetWeight)kg, カロリー\(calories)kcal, 性別\(gender)")
    }
}
