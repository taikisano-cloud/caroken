import Foundation

// MARK: - NetworkManager

class NetworkManager {
    static let shared = NetworkManager()
    
    // バックエンドのベースURL
    #if DEBUG
    let baseURL = "http://localhost:8000"
    #else
    let baseURL = "https://api.caloken.app"
    #endif
    
    // 認証トークン
    var authToken: String?
    
    private init() {}
    
    // MARK: - Health Check
    
    func healthCheck() async -> Bool {
        do {
            guard let url = URL(string: "\(baseURL)/health") else {
                return false
            }
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            print("Health check failed: \(error)")
            return false
        }
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
