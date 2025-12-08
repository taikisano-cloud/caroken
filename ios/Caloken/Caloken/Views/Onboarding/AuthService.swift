import Foundation
import SwiftUI
import Combine
import AuthenticationServices

// MARK: - Auth Service
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    // Supabase設定
    private let supabaseURL = "https://ekfcrkbnxkphtkyvozgw.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrZmNya2JueGtwaHRreXZvemd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxNjgzODEsImV4cCI6MjA4MDc0NDM4MX0.YjlRR95qCqWkANzi1-8yDAEfmhggEz-myg8emj3bYBo"
    
    // Google OAuth設定
    private let googleClientID = "40088442372-9uphm9n4epvhcvce58qfthn46ak991b5.apps.googleusercontent.com"
    
    // カスタムURLスキーム
    private let callbackURLScheme = "com.stellacreation.caloken"
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: AuthUser?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // ASWebAuthenticationSession用
    private var webAuthSession: ASWebAuthenticationSession?
    
    private override init() {
        super.init()
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
    
    // MARK: - Google Sign In (アプリ内ブラウザ)
    @MainActor
    func signInWithGoogle() async throws {
        isLoading = true
        
        // SupabaseのOAuth URLを生成
        let redirectURL = "\(callbackURLScheme)://login-callback"
        guard let encodedRedirect = redirectURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            isLoading = false
            throw AuthError.invalidURL
        }
        
        let authURLString = "\(supabaseURL)/auth/v1/authorize?provider=google&redirect_to=\(encodedRedirect)"
        
        guard let authURL = URL(string: authURLString) else {
            isLoading = false
            throw AuthError.invalidURL
        }
        
        // ASWebAuthenticationSessionを使用（アプリ内ブラウザ）
        return try await withCheckedThrowingContinuation { continuation in
            webAuthSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackURLScheme
            ) { [weak self] callbackURL, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    self.isLoading = false
                    
                    if let error = error {
                        if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            // ユーザーがキャンセル
                            continuation.resume(returning: ())
                            return
                        }
                        continuation.resume(throwing: AuthError.signInFailed)
                        return
                    }
                    
                    guard let callbackURL = callbackURL else {
                        continuation.resume(throwing: AuthError.invalidResponse)
                        return
                    }
                    
                    // コールバックURLからトークンを抽出
                    await self.processOAuthCallback(url: callbackURL)
                    continuation.resume(returning: ())
                }
            }
            
            // プレゼンテーションコンテキストを設定
            webAuthSession?.presentationContextProvider = self
            webAuthSession?.prefersEphemeralWebBrowserSession = false
            
            // 認証セッションを開始
            webAuthSession?.start()
        }
    }
    
    // MARK: - Process OAuth Callback
    @MainActor
    private func processOAuthCallback(url: URL) async {
        isLoading = true
        
        // URLからトークンを抽出
        // フラグメント（#以降）またはクエリパラメータから取得
        var params: [String: String] = [:]
        
        // フラグメントをチェック
        if let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment {
            fragment.split(separator: "&").forEach { pair in
                let keyValue = pair.split(separator: "=", maxSplits: 1)
                if keyValue.count == 2 {
                    params[String(keyValue[0])] = String(keyValue[1])
                }
            }
        }
        
        // クエリパラメータもチェック
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                if let value = item.value {
                    params[item.name] = value
                }
            }
        }
        
        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"] else {
            isLoading = false
            errorMessage = "認証トークンが見つかりません"
            return
        }
        
        // トークンを保存
        UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
        UserDefaults.standard.set(refreshToken, forKey: "supabase_refresh_token")
        
        // NetworkManagerにもトークンを設定
        UserDefaults.standard.set(accessToken, forKey: "accessToken")
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
        
        // ユーザー情報を取得
        await fetchUser(accessToken: accessToken)
    }
    
    // MARK: - Handle OAuth Callback (外部からの呼び出し用)
    @MainActor
    func handleOAuthCallback(url: URL) async {
        await processOAuthCallback(url: url)
    }
    
    // MARK: - Fetch User
    @MainActor
    private func fetchUser(accessToken: String) async {
        print("🔄 Fetching user info...")
        let startTime = Date()
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/user") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 10 // 10秒タイムアウト
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let elapsed = Date().timeIntervalSince(startTime)
            print("⏱️ User fetch took: \(String(format: "%.2f", elapsed))s")
            
            // HTTPステータスコードを確認
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP Status: \(httpResponse.statusCode)")
            }
            
            // レスポンスデータを確認
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response: \(jsonString.prefix(500))")
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📋 JSON keys: \(json.keys)")
                
                if let userId = json["id"] as? String {
                    let email = json["email"] as? String
                    
                    UserDefaults.standard.set(userId, forKey: "supabase_user_id")
                    UserDefaults.standard.set(email, forKey: "supabase_user_email")
                    
                    currentUser = AuthUser(id: userId, email: email)
                    isLoggedIn = true
                    isLoading = false
                    
                    print("✅ Google Sign In Success")
                    print("   User ID: \(userId)")
                    if let email = email {
                        print("   Email: \(email)")
                    }
                } else {
                    print("❌ No 'id' field in JSON")
                    isLoading = false
                }
            } else {
                print("❌ Failed to parse JSON")
                isLoading = false
            }
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            print("❌ User fetch failed after \(String(format: "%.2f", elapsed))s: \(error)")
            isLoading = false
            errorMessage = "ユーザー情報の取得に失敗しました"
        }
    }
    
    // MARK: - Email Sign Up
    @MainActor
    func signUp(email: String, password: String) async throws {
        isLoading = true
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/signup") else {
            isLoading = false
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
            isLoading = false
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
                
                currentUser = AuthUser(id: userId, email: email)
                isLoggedIn = true
                isLoading = false
            }
        } else {
            isLoading = false
            throw AuthError.signUpFailed
        }
    }
    
    // MARK: - Email Sign In
    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password") else {
            isLoading = false
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
            isLoading = false
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
                
                currentUser = AuthUser(id: userId, email: email)
                isLoggedIn = true
                isLoading = false
            }
        } else {
            isLoading = false
            throw AuthError.signInFailed
        }
    }
    
    // MARK: - Sign Out
    @MainActor
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "supabase_access_token")
        UserDefaults.standard.removeObject(forKey: "supabase_refresh_token")
        UserDefaults.standard.removeObject(forKey: "supabase_user_id")
        UserDefaults.standard.removeObject(forKey: "supabase_user_email")
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        
        isLoggedIn = false
        currentUser = nil
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // メインウィンドウを返す
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
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
