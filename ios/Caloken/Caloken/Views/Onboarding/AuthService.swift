import Foundation
import SwiftUI

// MARK: - Auth Service
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    // Supabase設定
    private let supabaseURL = "https://ekfcrkbnxkphtkyvozgw.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrZmNya2JueGtwaHRreXZvemd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM1NDc3NzMsImV4cCI6MjA0OTEyMzc3M30.b6sXKI-wlTIrlVFNgqyUaQ2IKG2tdrmMTRWJB_kNy5g"
    
    // Google OAuth設定
    private let googleClientID = "40088442372-9uphm9n4epvhcvce58qfthn46ak991b5.apps.googleusercontent.com"
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: AuthUser?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private init() {
        // 起動時にセッション確認
        checkSession()
    }
    
    // MARK: - Session Check
    func checkSession() {
        if let accessToken = UserDefaults.standard.string(forKey: "supabase_access_token"),
           let userId = UserDefaults.standard.string(forKey: "supabase_user_id"),
           !accessToken.isEmpty {
            isLoggedIn = true
            currentUser = AuthUser(id: userId, email: UserDefaults.standard.string(forKey: "supabase_user_email"))
        } else {
            isLoggedIn = false
            currentUser = nil
        }
    }
    
    // MARK: - Google Sign In (OAuth URL方式)
    func signInWithGoogle() async throws {
        await MainActor.run { isLoading = true }
        
        // SupabaseのOAuth URLを生成
        let redirectURL = "com.stellacreation.caloken://login-callback"
        let encodedRedirect = redirectURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURL
        
        let authURL = "\(supabaseURL)/auth/v1/authorize?provider=google&redirect_to=\(encodedRedirect)"
        
        guard let url = URL(string: authURL) else {
            await MainActor.run {
                isLoading = false
                errorMessage = "無効なURLです"
            }
            throw AuthError.invalidURL
        }
        
        // Safariで認証ページを開く
        await MainActor.run {
            UIApplication.shared.open(url)
            isLoading = false
        }
    }
    
    // MARK: - Handle OAuth Callback
    func handleOAuthCallback(url: URL) async {
        await MainActor.run { isLoading = true }
        
        // URLからトークンを抽出
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let fragment = components.fragment else {
            await MainActor.run {
                isLoading = false
                errorMessage = "認証情報が見つかりません"
            }
            return
        }
        
        // フラグメントからパラメータを解析
        var params: [String: String] = [:]
        fragment.split(separator: "&").forEach { pair in
            let keyValue = pair.split(separator: "=")
            if keyValue.count == 2 {
                params[String(keyValue[0])] = String(keyValue[1])
            }
        }
        
        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"] else {
            await MainActor.run {
                isLoading = false
                errorMessage = "トークンが見つかりません"
            }
            return
        }
        
        // トークンを保存
        UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
        UserDefaults.standard.set(refreshToken, forKey: "supabase_refresh_token")
        
        // ユーザー情報を取得
        await fetchUser(accessToken: accessToken)
    }
    
    // MARK: - Fetch User
    private func fetchUser(accessToken: String) async {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/user") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userId = json["id"] as? String {
                
                let email = json["email"] as? String
                
                UserDefaults.standard.set(userId, forKey: "supabase_user_id")
                UserDefaults.standard.set(email, forKey: "supabase_user_email")
                
                // NetworkManagerにもトークンを設定
                if let accessToken = UserDefaults.standard.string(forKey: "supabase_access_token") {
                    UserDefaults.standard.set(accessToken, forKey: "accessToken")
                }
                
                await MainActor.run {
                    currentUser = AuthUser(id: userId, email: email)
                    isLoggedIn = true
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "ユーザー情報の取得に失敗しました"
            }
        }
    }
    
    // MARK: - Email Sign Up
    func signUp(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/signup") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = json["access_token"] as? String,
               let user = json["user"] as? [String: Any],
               let userId = user["id"] as? String {
                
                UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
                UserDefaults.standard.set(userId, forKey: "supabase_user_id")
                UserDefaults.standard.set(email, forKey: "supabase_user_email")
                
                await MainActor.run {
                    currentUser = AuthUser(id: userId, email: email)
                    isLoggedIn = true
                    isLoading = false
                }
            }
        } else {
            await MainActor.run { isLoading = false }
            throw AuthError.signUpFailed
        }
    }
    
    // MARK: - Email Sign In
    func signIn(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = json["access_token"] as? String,
               let user = json["user"] as? [String: Any],
               let userId = user["id"] as? String {
                
                UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
                UserDefaults.standard.set(userId, forKey: "supabase_user_id")
                UserDefaults.standard.set(email, forKey: "supabase_user_email")
                
                // NetworkManagerにもトークンを設定
                UserDefaults.standard.set(accessToken, forKey: "accessToken")
                
                await MainActor.run {
                    currentUser = AuthUser(id: userId, email: email)
                    isLoggedIn = true
                    isLoading = false
                }
            }
        } else {
            await MainActor.run { isLoading = false }
            throw AuthError.signInFailed
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "supabase_access_token")
        UserDefaults.standard.removeObject(forKey: "supabase_refresh_token")
        UserDefaults.standard.removeObject(forKey: "supabase_user_id")
        UserDefaults.standard.removeObject(forKey: "supabase_user_email")
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        
        isLoggedIn = false
        currentUser = nil
    }
}

// MARK: - Auth User
struct AuthUser {
    let id: String
    let email: String?
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case signUpFailed
    case signInFailed
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです"
        case .invalidResponse: return "サーバーからの応答が無効です"
        case .signUpFailed: return "アカウント作成に失敗しました"
        case .signInFailed: return "ログインに失敗しました。メールアドレスまたはパスワードを確認してください"
        case .unauthorized: return "認証が必要です"
        }
    }
}
