import SwiftUI
import Combine

// MARK: - ユーザープロフィールマネージャー
final class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    // 基本情報
    @Published var name: String = ""
    @Published var gender: String = "未設定"
    @Published var age: Int = 30
    @Published var birthDate: Date = Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
    @Published var height: Double = 170.0
    @Published var currentWeight: Double = 65.0
    @Published var targetWeight: Double = 60.0
    @Published var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @Published var goal: String = "減量"
    @Published var exerciseFrequency: String = "週2-3回"
    
    // カロリー目標
    @Published var calorieGoal: Int = 2000
    
    // 栄養目標
    @Published var proteinGoal: Int = 60
    @Published var fatGoal: Int = 55
    @Published var carbGoal: Int = 250
    @Published var sugarGoal: Int = 50
    @Published var fiberGoal: Int = 20
    @Published var sodiumGoal: Int = 2300  // mg
    
    // オンボーディング
    @Published var hasCompletedOnboarding: Bool = false
    
    private let userDefaultsKey = "userProfile"
    
    private init() {
        loadProfile()
    }
    
    // MARK: - BMI計算
    var bmi: Double {
        guard height > 0 else { return 0 }
        let heightInMeters = height / 100
        return currentWeight / (heightInMeters * heightInMeters)
    }
    
    var bmiStatus: String {
        switch bmi {
        case ..<18.5: return "低体重"
        case 18.5..<25: return "標準"
        case 25..<30: return "過体重"
        default: return "肥満"
        }
    }
    
    // MARK: - 年齢計算
    var calculatedAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 30
    }
    
    // MARK: - 推奨カロリー計算（ハリス・ベネディクト方程式）
    func calculateRecommendedCalories() -> Int {
        var bmr: Double
        let useAge = calculatedAge
        
        if gender == "男性" || gender == "Male" {
            bmr = 88.362 + (13.397 * currentWeight) + (4.799 * height) - (5.677 * Double(useAge))
        } else {
            bmr = 447.593 + (9.247 * currentWeight) + (3.098 * height) - (4.330 * Double(useAge))
        }
        
        // 活動係数
        let activityMultiplier: Double
        switch exerciseFrequency {
        case "ほぼしない", "めったにしない": activityMultiplier = 1.2
        case "週1-2回", "たまに": activityMultiplier = 1.375
        case "週2-3回": activityMultiplier = 1.55
        case "週4-5回", "よくする": activityMultiplier = 1.725
        case "毎日": activityMultiplier = 1.9
        default: activityMultiplier = 1.55
        }
        
        var tdee = bmr * activityMultiplier
        
        // 目標に応じて調整
        switch goal {
        case "減量": tdee -= 500
        case "大幅減量": tdee -= 750
        case "増量": tdee += 300
        default: break  // 維持
        }
        
        return max(1200, Int(tdee))
    }
    
    // MARK: - 栄養目標を自動計算
    func calculateNutritionGoals() {
        let calories = calorieGoal
        
        // たんぱく質: 体重 × 1.6g（アクティブな人向け）
        proteinGoal = Int(currentWeight * 1.6)
        
        // 脂質: カロリーの25%
        fatGoal = Int(Double(calories) * 0.25 / 9)
        
        // 炭水化物: 残りのカロリー
        let proteinCalories = proteinGoal * 4
        let fatCalories = fatGoal * 9
        let remainingCalories = calories - proteinCalories - fatCalories
        carbGoal = max(100, remainingCalories / 4)
        
        // その他
        sugarGoal = 50
        fiberGoal = 25
        sodiumGoal = 2300
    }
    
    // MARK: - オンボーディングデータ設定
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
        self.currentWeight = Double(currentWeight)
        self.height = Double(height)
        self.targetWeight = Double(targetWeight)
        self.targetDate = targetDate
        self.calorieGoal = calories
        self.carbGoal = carbs
        self.proteinGoal = protein
        self.fatGoal = fat
        self.age = calculatedAge
        saveProfile()
    }
    
    // MARK: - オンボーディング完了
    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveProfile()
    }
    
    // MARK: - プロフィール保存
    func saveProfile() {
        let data: [String: Any] = [
            "name": name,
            "gender": gender,
            "age": age,
            "birthDate": birthDate.timeIntervalSince1970,
            "height": height,
            "currentWeight": currentWeight,
            "targetWeight": targetWeight,
            "targetDate": targetDate.timeIntervalSince1970,
            "goal": goal,
            "exerciseFrequency": exerciseFrequency,
            "calorieGoal": calorieGoal,
            "proteinGoal": proteinGoal,
            "fatGoal": fatGoal,
            "carbGoal": carbGoal,
            "sugarGoal": sugarGoal,
            "fiberGoal": fiberGoal,
            "sodiumGoal": sodiumGoal,
            "hasCompletedOnboarding": hasCompletedOnboarding
        ]
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    // MARK: - 栄養目標のみ保存
    func saveNutritionGoals() {
        saveProfile()
    }
    
    // MARK: - プロフィール読み込み
    private func loadProfile() {
        guard let data = UserDefaults.standard.dictionary(forKey: userDefaultsKey) else { return }
        
        name = data["name"] as? String ?? ""
        gender = data["gender"] as? String ?? "未設定"
        age = data["age"] as? Int ?? 30
        if let birthTimestamp = data["birthDate"] as? TimeInterval {
            birthDate = Date(timeIntervalSince1970: birthTimestamp)
        }
        height = data["height"] as? Double ?? 170.0
        currentWeight = data["currentWeight"] as? Double ?? 65.0
        targetWeight = data["targetWeight"] as? Double ?? 60.0
        if let targetTimestamp = data["targetDate"] as? TimeInterval {
            targetDate = Date(timeIntervalSince1970: targetTimestamp)
        }
        goal = data["goal"] as? String ?? "減量"
        exerciseFrequency = data["exerciseFrequency"] as? String ?? "週2-3回"
        calorieGoal = data["calorieGoal"] as? Int ?? 2000
        proteinGoal = data["proteinGoal"] as? Int ?? 60
        fatGoal = data["fatGoal"] as? Int ?? 55
        carbGoal = data["carbGoal"] as? Int ?? 250
        sugarGoal = data["sugarGoal"] as? Int ?? 50
        fiberGoal = data["fiberGoal"] as? Int ?? 20
        sodiumGoal = data["sodiumGoal"] as? Int ?? 2300
        hasCompletedOnboarding = data["hasCompletedOnboarding"] as? Bool ?? false
    }
    
    // MARK: - ユーザーコンテキスト（API用）
    func userContextForAPI() -> [String: Any] {
        let mealManager = MealLogsManager.shared
        let exerciseManager = ExerciseLogsManager.shared
        let today = Date()
        
        let todayMeals = mealManager.logs(for: today).map { $0.name }.joined(separator: "、")
        let nutrients = mealManager.totals(for: today)
        
        return [
            "gender": gender,
            "age": calculatedAge,
            "height": height,
            "current_weight": currentWeight,
            "target_weight": targetWeight,
            "bmi": round(bmi * 10) / 10,
            "bmi_status": bmiStatus,
            "goal": goal,
            "exercise_frequency": exerciseFrequency,
            "calorie_goal": calorieGoal,
            "protein_goal": proteinGoal,
            "fat_goal": fatGoal,
            "carb_goal": carbGoal,
            "today_calories": nutrients.calories,
            "today_protein": nutrients.protein,
            "today_fat": nutrients.fat,
            "today_carbs": nutrients.carbs,
            "today_exercise": exerciseManager.totalCaloriesBurned(for: today),
            "remaining_calories": calorieGoal - nutrients.calories + exerciseManager.totalCaloriesBurned(for: today),
            "today_meals": todayMeals
        ]
    }
    
    // MARK: - 全データをリセット（アカウント削除時に使用）
    func resetAllData() {
        // オンボーディング状態
        hasCompletedOnboarding = false
        
        // ユーザー情報をデフォルトに戻す
        name = ""
        goal = "減量"
        exerciseFrequency = "週2-3回"
        gender = "未設定"
        age = 30
        birthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
        currentWeight = 65.0
        height = 170.0
        targetWeight = 60.0
        targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        
        // 栄養目標をデフォルトに
        calorieGoal = 2000
        carbGoal = 250
        proteinGoal = 60
        fatGoal = 55
        sugarGoal = 50
        fiberGoal = 20
        sodiumGoal = 2300
        
        // UserDefaultsからプロフィールデータをクリア
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        print("🗑️ UserProfileManager: All data reset")
    }
}
