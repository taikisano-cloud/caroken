// NetworkManager.swift に追加するチャット関連のメソッド
// 既存のNetworkManagerクラスに以下のメソッドを追加/更新してください

import Foundation

// MARK: - NetworkManager拡張（チャットAPI）
extension NetworkManager {
    
    /// カロちゃんチャットAPI（モード対応版）
    /// - Parameters:
    ///   - message: ユーザーメッセージ
    ///   - imageBase64: 画像（Base64エンコード、オプション）
    ///   - chatHistory: 会話履歴
    ///   - userContext: ユーザーコンテキスト
    ///   - mode: "fast"（高速）または "thinking"（思考）
    /// - Returns: カロちゃんの返答
    func sendChatWithUserContext(
        message: String,
        imageBase64: String?,
        chatHistory: [[String: Any]],
        userContext: [String: Any],
        mode: String = "fast"  // デフォルトは高速モード
    ) async throws -> String {
        
        // APIエンドポイント
        let endpoint = "\(baseURL)/api/chat"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 認証トークンがあれば追加
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // リクエストボディ
        var body: [String: Any] = [
            "message": message,
            "chat_history": chatHistory,
            "user_context": userContext,
            "mode": mode  // モードを追加
        ]
        
        if let imageBase64 = imageBase64 {
            body["image_base64"] = imageBase64
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // リクエスト送信
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // レスポンスをパース
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw NetworkError.decodingError
        }
        
        return responseText
    }
    
    /// ホーム画面アドバイスAPI（高速モード固定）
    func fetchHomeAdvice(
        todayCalories: Int,
        goalCalories: Int,
        todayProtein: Int,
        todayFat: Int,
        todayCarbs: Int,
        todayMeals: String,
        mealCount: Int
    ) async throws -> String {
        
        let endpoint = "\(baseURL)/api/advice"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "today_calories": todayCalories,
            "goal_calories": goalCalories,
            "today_protein": todayProtein,
            "today_fat": todayFat,
            "today_carbs": todayCarbs,
            "today_meals": todayMeals,
            "meal_count": mealCount
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let advice = json["advice"] as? String else {
            throw NetworkError.decodingError
        }
        
        return advice
    }
    
    /// 食事コメント生成API（高速モード固定）
    func fetchMealComment(
        mealName: String,
        calories: Int,
        protein: Double,
        fat: Double,
        carbs: Double
    ) async throws -> String {
        
        let endpoint = "\(baseURL)/api/meal-comment"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "meal_name": mealName,
            "calories": calories,
            "protein": protein,
            "fat": fat,
            "carbs": carbs
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let comment = json["comment"] as? String else {
            throw NetworkError.decodingError
        }
        
        return comment
    }
}

// MARK: - NetworkError
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    case noData
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .serverError(let statusCode):
            return "サーバーエラー: \(statusCode)"
        case .decodingError:
            return "データの解析に失敗しました"
        case .noData:
            return "データがありません"
        }
    }
}
