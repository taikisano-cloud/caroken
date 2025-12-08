import Foundation

// MARK: - Auth Models
struct AuthRequest: Encodable {
    let email: String
    let password: String
}

struct TokenResponse: Decodable {
    let access_token: String
    let refresh_token: String
    let token_type: String
    let expires_in: Int
    let user_id: String
}

// MARK: - Profile Models
struct ProfileResponse: Decodable, Identifiable {
    let id: String
    let email: String?
    let display_name: String?
    let gender: String?
    let birth_date: String?
    let height_cm: Double?
    let target_weight_kg: Double?
    let activity_level: String?
    let goal: String?
    let daily_calorie_goal: Int?
    let daily_protein_goal: Int?
    let daily_fat_goal: Int?
    let daily_carbs_goal: Int?
    let created_at: String?
    let updated_at: String?
}

struct ProfileUpdate: Encodable {
    var display_name: String?
    var gender: String?
    var birth_date: String?
    var height_cm: Double?
    var target_weight_kg: Double?
    var activity_level: String?
    var goal: String?
    var daily_calorie_goal: Int?
    var daily_protein_goal: Int?
    var daily_fat_goal: Int?
    var daily_carbs_goal: Int?
}

// MARK: - Meal Models
struct MealLogCreate: Encodable {
    let name: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    var sugar: Double = 0
    var fiber: Double = 0
    var sodium: Double = 0
    var emoji: String = "🍽️"
    var image_url: String?
    var logged_at: String?
}

struct MealLogResponse: Decodable, Identifiable {
    let id: String
    let user_id: String
    let name: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let sugar: Double
    let fiber: Double
    let sodium: Double
    let emoji: String
    let image_url: String?
    let logged_at: String
    let created_at: String
}

struct DailyMealSummary: Decodable {
    let date: String
    let total_calories: Int
    let total_protein: Double
    let total_fat: Double
    let total_carbs: Double
    let meal_count: Int
    let meals: [MealLogResponse]
}

// MARK: - Exercise Models
struct ExerciseLogCreate: Encodable {
    let name: String
    var exercise_type: String = "other"
    var duration_minutes: Int = 0
    var calories_burned: Int = 0
    var distance_km: Double?
    var steps: Int?
    var logged_at: String?
}

struct ExerciseLogResponse: Decodable, Identifiable {
    let id: String
    let user_id: String
    let name: String
    let exercise_type: String
    let duration_minutes: Int
    let calories_burned: Int
    let distance_km: Double?
    let steps: Int?
    let logged_at: String
    let created_at: String
}

struct DailyExerciseSummary: Decodable {
    let date: String
    let total_calories_burned: Int
    let total_duration_minutes: Int
    let exercise_count: Int
    let exercises: [ExerciseLogResponse]
}

// MARK: - Weight Models
struct WeightLogCreate: Encodable {
    let weight_kg: Double
    var logged_at: String?
}

struct WeightLogResponse: Decodable, Identifiable {
    let id: String
    let user_id: String
    let weight_kg: Double
    let logged_at: String
    let created_at: String
}

struct WeightHistory: Decodable {
    let logs: [WeightLogResponse]
    let current_weight: Double?
    let start_weight: Double?
    let weight_change: Double?
    let target_weight: Double?
}

// MARK: - AI Models
struct MealAnalysisRequest: Encodable {
    let image_base64: String?
    let description: String?
}

struct FoodItem: Decodable, Identifiable {
    var id: String { name }
    let name: String
    let amount: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
}

struct DetailedMealAnalysis: Decodable {
    let food_items: [FoodItem]
    let total_calories: Int
    let total_protein: Double
    let total_fat: Double
    let total_carbs: Double
    let total_sugar: Double
    let total_fiber: Double
    let total_sodium: Double
    let character_comment: String
}

struct ChatRequest: Encodable {
    let message: String
    let image_base64: String?
    var chat_date: String?
}

struct ChatMessageResponse: Decodable, Identifiable {
    let id: String
    let user_id: String
    let message: String?
    let image_url: String?
    let is_user: Bool
    let chat_date: String
    let created_at: String
}

struct ChatResponse: Decodable {
    let response: String
    let user_message: ChatMessageResponse
    let ai_message: ChatMessageResponse
}

// MARK: - Stats Models
struct DailySummary: Decodable {
    let date: String
    let calories_consumed: Int
    let calories_burned: Int
    let net_calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let meal_count: Int
    let exercise_count: Int
    let weight: Double?
}

struct WeeklySummary: Decodable {
    let start_date: String
    let end_date: String
    let avg_calories_consumed: Double
    let avg_calories_burned: Double
    let total_calories_consumed: Int
    let total_calories_burned: Int
    let avg_protein: Double
    let avg_fat: Double
    let avg_carbs: Double
    let weight_change: Double?
    let daily_data: [DailySummary]
}

struct GoalProgress: Decodable {
    let calorie_goal: Int
    let calories_consumed: Int
    let calories_remaining: Int
    let calories_burned: Int
    let net_calories: Int
    let protein_goal: Int
    let protein_consumed: Double
    let fat_goal: Int
    let fat_consumed: Double
    let carbs_goal: Int
    let carbs_consumed: Double
    let calorie_progress_percent: Double
    let protein_progress_percent: Double
    let fat_progress_percent: Double
    let carbs_progress_percent: Double
}
