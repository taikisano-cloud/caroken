import Foundation
import SwiftUI
import Combine

// MARK: - Network Manager
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "https://caroken-production.up.railway.app/api"
    
    // ⭐ デバッグモード - trueでログイン不要のテストAPIを使用
    var isDebugMode: Bool = true
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "accessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "accessToken") }
    }
    
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "refreshToken") }
        set { UserDefaults.standard.set(newValue, forKey: "refreshToken") }
    }
    
    var isLoggedIn: Bool {
        accessToken != nil
    }
    
    var currentUserId: String? {
        UserDefaults.standard.string(forKey: "userId")
    }
    
    private init() {}
    
    // MARK: - Generic Request
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            if let _ = refreshToken {
                try await refreshAccessToken()
                return try await self.request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
            } else {
                throw NetworkError.unauthorized
            }
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.serverError(errorResponse.detail)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Auth
    func signup(email: String, password: String) async throws -> TokenResponse {
        let body = AuthRequest(email: email, password: password)
        let response: TokenResponse = try await request(
            endpoint: "/auth/signup",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        saveTokens(response)
        return response
    }
    
    func login(email: String, password: String) async throws -> TokenResponse {
        let body = AuthRequest(email: email, password: password)
        let response: TokenResponse = try await request(
            endpoint: "/auth/login",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        saveTokens(response)
        return response
    }
    
    func logout() {
        accessToken = nil
        refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "userId")
    }
    
    private func saveTokens(_ response: TokenResponse) {
        accessToken = response.access_token
        refreshToken = response.refresh_token
        UserDefaults.standard.set(response.user_id, forKey: "userId")
    }
    
    private func refreshAccessToken() async throws {
        guard let token = refreshToken else {
            throw NetworkError.unauthorized
        }
        
        let response: TokenResponse = try await request(
            endpoint: "/auth/refresh?refresh_token=\(token)",
            method: "POST",
            requiresAuth: false
        )
        saveTokens(response)
    }
    
    // MARK: - Profile
    func getProfile() async throws -> ProfileResponse {
        try await request(endpoint: "/users/me")
    }
    
    func updateProfile(_ profile: ProfileUpdate) async throws -> ProfileResponse {
        try await request(endpoint: "/users/me", method: "PUT", body: profile)
    }
    
    // MARK: - Meals
    func createMeal(_ meal: MealLogCreate) async throws -> MealLogResponse {
        try await request(endpoint: "/meals", method: "POST", body: meal)
    }
    
    func getMeals(date: String? = nil) async throws -> [MealLogResponse] {
        var endpoint = "/meals"
        if let date = date {
            endpoint += "?date=\(date)"
        }
        return try await request(endpoint: endpoint)
    }
    
    func getDailyMealSummary(date: String) async throws -> DailyMealSummary {
        try await request(endpoint: "/meals/daily/\(date)")
    }
    
    func deleteMeal(id: String) async throws {
        let _: EmptyResponse = try await request(endpoint: "/meals/\(id)", method: "DELETE")
    }
    
    // MARK: - Exercises
    func createExercise(_ exercise: ExerciseLogCreate) async throws -> ExerciseLogResponse {
        try await request(endpoint: "/exercises", method: "POST", body: exercise)
    }
    
    func getExercises(date: String? = nil) async throws -> [ExerciseLogResponse] {
        var endpoint = "/exercises"
        if let date = date {
            endpoint += "?date=\(date)"
        }
        return try await request(endpoint: endpoint)
    }
    
    func getDailyExerciseSummary(date: String) async throws -> DailyExerciseSummary {
        try await request(endpoint: "/exercises/daily/\(date)")
    }
    
    func deleteExercise(id: String) async throws {
        let _: EmptyResponse = try await request(endpoint: "/exercises/\(id)", method: "DELETE")
    }
    
    // MARK: - Weights
    func createWeight(_ weight: WeightLogCreate) async throws -> WeightLogResponse {
        try await request(endpoint: "/weights", method: "POST", body: weight)
    }
    
    func getWeightHistory(days: Int = 30) async throws -> WeightHistory {
        try await request(endpoint: "/weights/history?days=\(days)")
    }
    
    func getLatestWeight() async throws -> WeightLogResponse? {
        try await request(endpoint: "/weights/latest")
    }
    
    // MARK: - AI (デバッグモード対応)
    func analyzeMeal(imageBase64: String? = nil, description: String? = nil) async throws -> DetailedMealAnalysis {
        let body = MealAnalysisRequest(image_base64: imageBase64, description: description)
        
        // デバッグモードならテストエンドポイントを使用
        let endpoint = isDebugMode ? "/ai/analyze-meal/test" : "/ai/analyze-meal"
        
        return try await request(endpoint: endpoint, method: "POST", body: body, requiresAuth: !isDebugMode)
    }
    
    func chat(message: String, imageBase64: String? = nil) async throws -> ChatResponse {
        // デバッグモードならテストエンドポイントを使用
        if isDebugMode {
            let body = TestChatRequest(message: message, image_base64: imageBase64)
            let testResponse: TestChatResponse = try await request(
                endpoint: "/ai/chat/test",
                method: "POST",
                body: body,
                requiresAuth: false
            )
            // TestChatResponseをChatResponseに変換
            return ChatResponse(
                response: testResponse.response,
                user_message: nil,
                ai_message: nil
            )
        } else {
            let body = ChatRequest(message: message, image_base64: imageBase64)
            return try await request(endpoint: "/ai/chat", method: "POST", body: body)
        }
    }
    
    func getChatHistory(date: String? = nil) async throws -> [ChatMessageResponse] {
        var endpoint = "/ai/chat/history"
        if let date = date {
            endpoint += "?chat_date=\(date)"
        }
        return try await request(endpoint: endpoint)
    }
    
    // MARK: - Stats
    func getDailySummary(date: String) async throws -> DailySummary {
        try await request(endpoint: "/stats/daily/\(date)")
    }
    
    func getWeeklySummary(startDate: String? = nil) async throws -> WeeklySummary {
        var endpoint = "/stats/weekly"
        if let startDate = startDate {
            endpoint += "?start_date=\(startDate)"
        }
        return try await request(endpoint: endpoint)
    }
    
    func getTodayProgress() async throws -> GoalProgress {
        try await request(endpoint: "/stats/today/progress")
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpError(Int)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .unauthorized:
            return "認証が必要です。再度ログインしてください"
        case .httpError(let code):
            return "エラーが発生しました (コード: \(code))"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Test Request/Response
struct TestChatRequest: Encodable {
    let message: String
    let image_base64: String?
}

struct TestChatResponse: Decodable {
    let response: String
}

// MARK: - Empty Response for DELETE
struct EmptyResponse: Decodable {
    var message: String?
}

struct ErrorResponse: Decodable {
    let detail: String
}
