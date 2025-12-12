// NetworkManager+FeatureRequests.swift
// 機能リクエスト関連のNetworkManager拡張

import Foundation

// MARK: - データモデル

struct FeatureRequestAPI: Codable, Identifiable {
    let id: String
    let authorId: String
    let authorName: String
    let title: String
    let description: String
    let votes: Int
    let status: String
    let hasVoted: Bool
    let isOwner: Bool
    let comments: [FeatureCommentAPI]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case authorName = "author_name"
        case title
        case description
        case votes
        case status
        case hasVoted = "has_voted"
        case isOwner = "is_owner"
        case comments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct FeatureCommentAPI: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let content: String
    let createdAt: String
    let isOwner: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case content
        case createdAt = "created_at"
        case isOwner = "is_owner"
    }
}

struct VoteResponse: Codable {
    let voted: Bool
    let message: String
}

// MARK: - NetworkManager拡張

extension NetworkManager {
    
    
    /// 全ての機能リクエストを取得
    func getFeatureRequests() async throws -> [FeatureRequestAPI] {
        
        let endpoint = "\(baseURL)/feature-requests"
        
        debugPrint("📋 Get Feature Requests: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを追加
        if let token = UserDefaults.standard.string(forKey: "supabase_access_token") {
            debugPrint("🔑 Token prefix: \(String(token.prefix(50)))...")  // ← 追加

            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        debugPrint("  - Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([FeatureRequestAPI].self, from: data)
    }
    
    
    /// 特定の機能リクエストを取得（コメント含む）
    func getFeatureRequest(id: String) async throws -> FeatureRequestAPI {
        let endpoint = "\(baseURL)/feature-requests/\(id)"
        
        debugPrint("📋 Get Feature Request: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "supabase_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(FeatureRequestAPI.self, from: data)
    }
    
    /// 新しい機能リクエストを作成
    func createFeatureRequest(title: String, description: String) async throws -> FeatureRequestAPI {
        let endpoint = "\(baseURL)/feature-requests"
        
        debugPrint("📋 Create Feature Request: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "supabase_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "title": title,
            "description": description
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        debugPrint("  - Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(FeatureRequestAPI.self, from: data)
    }
    
    /// 機能リクエストを削除
    func deleteFeatureRequest(id: String) async throws {
        let endpoint = "\(baseURL)/feature-requests/\(id)"
        
        debugPrint("📋 Delete Feature Request: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = UserDefaults.standard.string(forKey: "supabase_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// 投票のトグル
    func toggleFeatureRequestVote(requestId: String) async throws -> VoteResponse {
        let endpoint = "\(baseURL)/feature-requests/\(requestId)/vote"
        
        debugPrint("📋 Toggle Vote: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = UserDefaults.standard.string(forKey: "supabase_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        debugPrint("  - Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(VoteResponse.self, from: data)
    }
    
    /// コメントを追加
    func addFeatureRequestComment(requestId: String, content: String) async throws -> FeatureCommentAPI {
        let endpoint = "\(baseURL)/feature-requests/\(requestId)/comments"
        
        debugPrint("📋 Add Comment: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "supabase_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = ["content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        debugPrint("  - Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(FeatureCommentAPI.self, from: data)
    }
    
    /// コメントを削除
    func deleteFeatureRequestComment(requestId: String, commentId: String) async throws {
        let endpoint = "\(baseURL)/feature-requests/\(requestId)/comments/\(commentId)"
        
        debugPrint("📋 Delete Comment: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = UserDefaults.standard.string(forKey: "supabase_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
