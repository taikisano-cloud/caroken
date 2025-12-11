// NetworkManager+Chat.swift
// チャット関連のNetworkManager拡張

import Foundation

// MARK: - NetworkManager拡張（チャットAPI）
extension NetworkManager {
    
    /// カロちゃんチャットAPI（モード対応版）
    func sendChatWithUserContext(
        message: String,
        imageBase64: String?,
        chatHistory: [[String: Any]],
        userContext: [String: Any],
        mode: String = "fast"
    ) async throws -> String {
        
        let endpoint = "\(baseURL)/v1/chat"
        
        print("💬 Chat Request: \(endpoint)")
        print("  - Mode: \(mode)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "message": message,
            "chat_history": chatHistory,
            "user_context": userContext,
            "mode": mode
        ]
        
        if let imageBase64 = imageBase64 {
            body["image_base64"] = imageBase64
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("  - Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("  - Error: \(errorString)")
            }
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw NetworkError.decodingError
        }
        
        return responseText
    }
    
    /// ホーム画面アドバイスAPI（時間帯・食事詳細対応版）
    func fetchHomeAdvice(
        todayCalories: Int,
        goalCalories: Int,
        todayProtein: Int,
        todayFat: Int,
        todayCarbs: Int,
        todayMeals: String,
        mealCount: Int,
        breakfastCount: Int = 0,
        lunchCount: Int = 0,
        dinnerCount: Int = 0,
        snackCount: Int = 0
    ) async throws -> String {
        
        let endpoint = "\(baseURL)/v1/advice"
        
        // 現在の時間帯を計算
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        let timeContext: String
        
        if hour < 10 {
            timeOfDay = "morning"
            timeContext = "朝"
        } else if hour < 14 {
            timeOfDay = "noon"
            timeContext = "昼"
        } else if hour < 18 {
            timeOfDay = "afternoon"
            timeContext = "夕方"
        } else {
            timeOfDay = "evening"
            timeContext = "夜"
        }
        
        print("📝 Advice Request: \(endpoint)")
        print("  - Time: \(timeContext) (\(hour)時)")
        print("  - Meals: 朝\(breakfastCount) 昼\(lunchCount) 夕\(dinnerCount) 間食\(snackCount)")
        print("  - Total: \(todayCalories)/\(goalCalories) kcal")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "today_calories": todayCalories,
            "goal_calories": goalCalories,
            "today_protein": todayProtein,
            "today_fat": todayFat,
            "today_carbs": todayCarbs,
            "today_meals": todayMeals,
            "meal_count": mealCount,
            "breakfast_count": breakfastCount,
            "lunch_count": lunchCount,
            "dinner_count": dinnerCount,
            "snack_count": snackCount,
            "current_hour": hour,
            "time_of_day": timeOfDay,
            "time_context": timeContext
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("  - Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("  - Error: \(errorString)")
            }
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let advice = json["advice"] as? String else {
            throw NetworkError.decodingError
        }
        
        return advice
    }
    
    /// 食事コメント生成API（Flashモデル使用 - 高速）
    func fetchMealComment(
        mealName: String,
        calories: Int,
        protein: Double,
        fat: Double,
        carbs: Double,
        sugar: Double = 0,
        fiber: Double = 0,
        sodium: Double = 0
    ) async throws -> String {
        
        let endpoint = "\(baseURL)/v1/meal-comment"
        
        print("🍽️ Meal Comment Request: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "meal_name": mealName,
            "calories": calories,
            "protein": protein,
            "fat": fat,
            "carbs": carbs,
            "sugar": sugar,
            "fiber": fiber,
            "sodium": sodium
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("  - Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("  - Error: \(errorString)")
            }
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let comment = json["comment"] as? String else {
            throw NetworkError.decodingError
        }
        
        return comment
    }
}

// MARK: - HomeAdviceManager互換（旧API対応）
extension NetworkManager {
    func getHomeAdvice(
        todayCalories: Int,
        goalCalories: Int,
        todayProtein: Int,
        todayFat: Int,
        todayCarbs: Int,
        todayMeals: String,
        mealCount: Int
    ) async throws -> String {
        return try await fetchHomeAdvice(
            todayCalories: todayCalories,
            goalCalories: goalCalories,
            todayProtein: todayProtein,
            todayFat: todayFat,
            todayCarbs: todayCarbs,
            todayMeals: todayMeals,
            mealCount: mealCount
        )
    }
}

// MARK: - 食事分析API
extension NetworkManager {
    
    /// 食事画像を分析（Proモデル使用）
    func analyzeMeal(imageBase64: String) async throws -> MealAnalysisData {
        let endpoint = "\(baseURL)/v1/analyze-meal"
        
        print("🍽️ Meal Analysis (Image):")
        print("  - URL: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "image_base64": imageBase64
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("  - Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("  - Error: \(errorString)")
            }
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("  - Response: \(jsonString.prefix(300))...")
        }
    
        let result = try JSONDecoder().decode(MealAnalysisData.self, from: data)
        return result
    }
    
    /// 食事テキストを分析（Proモデル使用）
    func analyzeMeal(description: String) async throws -> MealAnalysisData {
        let endpoint = "\(baseURL)/v1/analyze-meal"
        
        print("🍽️ Meal Analysis (Text):")
        print("  - URL: \(endpoint)")
        print("  - Description: \(description)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "description": description
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("  - Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("  - Error: \(errorString)")
            }
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("  - Response: \(jsonString.prefix(300))...")
        }
        
        let result = try JSONDecoder().decode(MealAnalysisData.self, from: data)
        return result
    }
}

// MARK: - API Response Models
private struct MealAnalysisAPIResponse: Codable {
    let analysis: MealAnalysisData
}
