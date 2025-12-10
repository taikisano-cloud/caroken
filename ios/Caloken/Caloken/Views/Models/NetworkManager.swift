import Foundation

// MARK: - NetworkManager

// MARK: - 食事分析API
extension NetworkManager {
    
    /// 食事画像を分析
    func analyzeMeal(imageBase64: String) async throws -> MealAnalysisData {
        // ✅ 正しいエンドポイント
        let endpoint = "\(baseURL)/ai/analyze-meal/test"
        
        print("🍽️ Meal Analysis (Image):")
        print("  - URL: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 認証不要（テストエンドポイント）
        
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
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(MealAnalysisData.self, from: data)
    }
    
    /// 食事テキストを分析
    func analyzeMeal(description: String) async throws -> MealAnalysisData {
        // ✅ 正しいエンドポイント
        let endpoint = "\(baseURL)/ai/analyze-meal/test"
        
        print("🍽️ Meal Analysis (Text):")
        print("  - URL: \(endpoint)")
        print("  - Description: \(description)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 認証不要（テストエンドポイント）
        
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
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(MealAnalysisData.self, from: data)
    }
}

// MARK: - NetworkError

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    case noData
    case unauthorized
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .serverError(let code):
            return "サーバーエラー (コード: \(code))"
        case .decodingError:
            return "データの解析に失敗しました"
        case .noData:
            return "データがありません"
        case .unauthorized:
            return "認証が必要です"
        case .networkUnavailable:
            return "ネットワークに接続できません"
        }
    }
}
