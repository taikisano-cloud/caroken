import Foundation

// MARK: - NetworkManager
class NetworkManager {
    static let shared = NetworkManager()
    
    let baseURL = "https://caloken-backend-production.up.railway.app/api"
    
    private init() {}
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
