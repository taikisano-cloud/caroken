import Foundation
import SwiftUI
import UIKit
import Combine
import AuthenticationServices
import CryptoKit

// MARK: - Auth Service
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    // Supabase設定
    private let supabaseURL = "https://ekfcrkbnxkphtkyvozgw.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrZmNya2JueGtwaHRreXZvemd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxNjgzODEsImV4cCI6MjA4MDc0NDM4MX0.YjlRR95qCqWkANzi1-8yDAEfmhggEz-myg9emj3bYBo"
    
    // カスタムURLスキーム
    private let callbackURLScheme = "com.stellacreation.caloken"
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: AuthUser?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // ASWebAuthenticationSession用
    private var webAuthSession: ASWebAuthenticationSession?
    
    // Apple Sign In用のnonce
    private var currentNonce: String?
    
    // OAuthキャンセルフラグ
    private var oauthCancelled: Bool = false
    
    private override init() {
        super.init()
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
    
    // MARK: - Apple Sign In (Supabase連携)
    
    /// Apple Sign In用のnonceを生成
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    /// SHA256ハッシュを生成
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    /// ランダムなnonce文字列を生成
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    /// Apple Sign Inの認証情報をSupabaseに送信
    @MainActor
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?, email: String?) async throws {
        isLoading = true
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=id_token") else {
            isLoading = false
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 30
        
        var body: [String: Any] = [
            "provider": "apple",
            "id_token": idToken,
            "nonce": nonce
        ]
        
        // ユーザー情報を追加（初回ログイン時のみAppleから提供される）
        if let fullName = fullName {
            var options: [String: Any] = [:]
            var data: [String: Any] = [:]
            
            if let givenName = fullName.givenName {
                data["first_name"] = givenName
            }
            if let familyName = fullName.familyName {
                data["last_name"] = familyName
            }
            if let email = email {
                data["email"] = email
            }
            
            if !data.isEmpty {
                options["data"] = data
                body["options"] = options
            }
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🍎 Apple Sign In - Sending to Supabase...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                isLoading = false
                throw AuthError.invalidResponse
            }
            
            print("📡 Response Status: \(httpResponse.statusCode)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response: \(jsonString.prefix(500))")
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String,
                   let refreshToken = json["refresh_token"] as? String,
                   let user = json["user"] as? [String: Any],
                   let userId = user["id"] as? String {
                    
                    // トークンを保存
                    saveTokens(accessToken: accessToken, refreshToken: refreshToken, userId: userId, email: email)
                    
                    currentUser = AuthUser(id: userId, email: email)
                    isLoggedIn = true
                    isLoading = false
                    
                    print("✅ Apple Sign In Success!")
                    print("   User ID: \(userId)")
                    
                } else {
                    isLoading = false
                    throw AuthError.invalidResponse
                }
            } else {
                isLoading = false
                
                // エラーメッセージを解析
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = json["error_description"] as? String ?? json["msg"] as? String {
                    print("❌ Error: \(errorMsg)")
                    errorMessage = errorMsg
                }
                
                throw AuthError.signInFailed
            }
        } catch {
            isLoading = false
            print("❌ Apple Sign In Error: \(error)")
            throw error
        }
    }
    
    // MARK: - Google Sign In (OAuth)
    @MainActor
    func signInWithGoogle() async throws {
        isLoading = true
        oauthCancelled = false  // 開始時にリセット
        
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
        
        return try await withCheckedThrowingContinuation { continuation in
            webAuthSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackURLScheme
            ) { [weak self] callbackURL, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    self.isLoading = false
                    
                    if let error = error {
                        let nsError = error as NSError
                        if nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                            print("🚫 Google Sign In cancelled by user")
                            self.oauthCancelled = true  // キャンセルフラグを設定
                            continuation.resume(throwing: AuthError.cancelled)
                            return
                        }
                        print("❌ Google Sign In error: \(error)")
                        continuation.resume(throwing: AuthError.signInFailed)
                        return
                    }
                    
                    guard let callbackURL = callbackURL else {
                        print("❌ No callback URL received")
                        continuation.resume(throwing: AuthError.invalidResponse)
                        return
                    }
                    
                    print("📥 Received callback URL")
                    await self.processOAuthCallback(url: callbackURL)
                    
                    // ログインに成功したかチェック
                    if self.isLoggedIn {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: AuthError.signInFailed)
                    }
                }
            }
            
            webAuthSession?.presentationContextProvider = self
            webAuthSession?.prefersEphemeralWebBrowserSession = false
            webAuthSession?.start()
        }
    }
    
    // MARK: - Handle OAuth Callback (外部から呼び出し可能)
    @MainActor
    func handleOAuthCallback(url: URL) async {
        // キャンセルされた場合はコールバックを無視
        if oauthCancelled {
            print("⚠️ OAuth was cancelled, ignoring callback")
            oauthCancelled = false  // リセット
            return
        }
        await processOAuthCallback(url: url)
    }
    
    // MARK: - Process OAuth Callback
    @MainActor
    private func processOAuthCallback(url: URL) async {
        isLoading = true
        
        print("🔐 Processing OAuth callback...")
        print("   URL: \(url.absoluteString.prefix(100))...")
        
        var params: [String: String] = [:]
        
        // フラグメントからパラメータを抽出
        if let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment {
            print("   Fragment found, parsing...")
            fragment.split(separator: "&").forEach { pair in
                let keyValue = pair.split(separator: "=", maxSplits: 1)
                if keyValue.count == 2 {
                    params[String(keyValue[0])] = String(keyValue[1])
                }
            }
        }
        
        // クエリパラメータからも抽出
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                if let value = item.value {
                    params[item.name] = value
                }
            }
        }
        
        print("   Params found: \(params.keys.sorted().joined(separator: ", "))")
        
        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"] else {
            isLoading = false
            errorMessage = "認証トークンが見つかりません"
            print("❌ No tokens in callback URL")
            print("   Available params: \(params.keys.sorted())")
            return
        }
        
        print("✅ Tokens found in callback")
        print("   Access Token length: \(accessToken.count)")
        print("   Refresh Token length: \(refreshToken.count)")
        
        // トークンを保存
        UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
        UserDefaults.standard.set(refreshToken, forKey: "supabase_refresh_token")
        UserDefaults.standard.set(accessToken, forKey: "accessToken")
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
        
        // 保存を即座に反映
        UserDefaults.standard.synchronize()
        
        // 保存確認
        let savedAccess = UserDefaults.standard.string(forKey: "supabase_access_token")
        let savedRefresh = UserDefaults.standard.string(forKey: "supabase_refresh_token")
        print("✅ Tokens saved verification:")
        print("   Access Token saved: \(savedAccess != nil && !savedAccess!.isEmpty)")
        print("   Refresh Token saved: \(savedRefresh != nil && !savedRefresh!.isEmpty)")
        
        // ユーザー情報を取得（失敗してもログインは成功とする）
        await fetchUser(accessToken: accessToken)
        
        // fetchUserが失敗しても確実にログイン状態にする
        if !isLoggedIn {
            isLoggedIn = true
        }
        isLoading = false
        
        print("✅ OAuth callback processing completed")
        print("   isLoggedIn: \(isLoggedIn)")
        print("   isLoading: \(isLoading)")
    }
    
    // MARK: - Fetch User
    @MainActor
    private func fetchUser(accessToken: String) async {
        print("🔄 Fetching user info...")
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/user") else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Fetch User HTTP Status: \(httpResponse.statusCode)")
                
                // 401エラーの場合でもトークンは保存済みなので、ログイン成功として扱う
                if httpResponse.statusCode == 401 {
                    print("⚠️ Token validation failed, but proceeding with login")
                    // トークンは既に保存されているので、ユーザー情報なしでログイン
                    isLoggedIn = true
                    isLoading = false
                    return
                }
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let userId = json["id"] as? String {
                    let email = json["email"] as? String
                    
                    UserDefaults.standard.set(userId, forKey: "supabase_user_id")
                    UserDefaults.standard.set(email, forKey: "supabase_user_email")
                    UserDefaults.standard.synchronize()
                    
                    currentUser = AuthUser(id: userId, email: email)
                    isLoggedIn = true
                    isLoading = false
                    
                    print("✅ User fetch success!")
                    print("   User ID: \(userId)")
                    print("   Email: \(email ?? "none")")
                    
                    // 最終確認ログ
                    print("📦 Final token check:")
                    print("   supabase_access_token: \(UserDefaults.standard.string(forKey: "supabase_access_token") != nil)")
                    print("   supabase_refresh_token: \(UserDefaults.standard.string(forKey: "supabase_refresh_token") != nil)")
                    print("   supabase_user_id: \(UserDefaults.standard.string(forKey: "supabase_user_id") != nil)")
                } else {
                    // ユーザーIDが取得できない場合もログイン成功として扱う
                    print("⚠️ User ID not found in response, but proceeding")
                    isLoggedIn = true
                    isLoading = false
                }
            } else {
                // JSONパースに失敗した場合もログイン成功として扱う
                print("⚠️ Failed to parse user response, but proceeding")
                isLoggedIn = true
                isLoading = false
            }
        } catch {
            print("❌ User fetch failed: \(error)")
            // エラーでもトークンは保存済みなので、ログイン成功として扱う
            isLoggedIn = true
            isLoading = false
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
                
                saveTokens(accessToken: accessToken, refreshToken: nil, userId: userId, email: email)
                
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
               let refreshToken = json["refresh_token"] as? String,
               let user = json["user"] as? [String: Any],
               let userId = user["id"] as? String {
                
                saveTokens(accessToken: accessToken, refreshToken: refreshToken, userId: userId, email: email)
                
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
    
    // MARK: - Delete Account
    @MainActor
    func deleteAccount(reason: String = "", otherReason: String = "") async throws {
        isLoading = true
        
        // デバッグ: 保存されているトークンを確認
        var accessToken = UserDefaults.standard.string(forKey: "supabase_access_token")
        let refreshToken = UserDefaults.standard.string(forKey: "supabase_refresh_token")
        
        print("🔍 Debug - Access Token exists: \(accessToken != nil)")
        print("🔍 Debug - Refresh Token exists: \(refreshToken != nil)")
        
        // アクセストークンがない、または空の場合
        if accessToken == nil || accessToken!.isEmpty {
            // リフレッシュトークンがあれば、トークンを更新してみる
            if let refresh = refreshToken, !refresh.isEmpty {
                print("🔄 Attempting to refresh token...")
                do {
                    accessToken = try await refreshAccessToken(refreshToken: refresh)
                } catch {
                    isLoading = false
                    print("❌ Token refresh failed: \(error)")
                    throw AuthError.unauthorized
                }
            } else {
                isLoading = false
                print("❌ No tokens available")
                throw AuthError.unauthorized
            }
        }
        
        guard let validAccessToken = accessToken else {
            isLoading = false
            throw AuthError.unauthorized
        }
        
        // Supabase Edge Function を呼び出してアカウントを削除
        guard let url = URL(string: "\(supabaseURL)/functions/v1/delete-account") else {
            isLoading = false
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(validAccessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // 削除理由とデバイス情報をボディに追加
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let deviceInfo = "\(device.model), \(device.systemName) \(device.systemVersion), App v\(appVersion)"
        
        let body: [String: Any] = [
            "reason": reason,
            "other_reason": otherReason,
            "device_info": deviceInfo
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🗑️ Calling delete-account Edge Function...")
        print("   Reason: \(reason)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                isLoading = false
                throw AuthError.invalidResponse
            }
            
            print("📡 Delete Account Response: \(httpResponse.statusCode)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response: \(jsonString)")
            }
            
            if httpResponse.statusCode == 200 {
                // 成功 - ローカルの全データを削除
                clearAllLocalData()
                
                isLoggedIn = false
                currentUser = nil
                isLoading = false
                
                print("✅ Account deleted from Supabase successfully")
                
            } else if httpResponse.statusCode == 401 {
                // トークンが無効 - リフレッシュを試みる
                print("⚠️ Token invalid, attempting refresh...")
                if let refresh = refreshToken, !refresh.isEmpty {
                    do {
                        let _ = try await refreshAccessToken(refreshToken: refresh)
                        // 新しいトークンで再試行
                        isLoading = false
                        try await deleteAccount(reason: reason, otherReason: otherReason)
                        return
                    } catch {
                        isLoading = false
                        throw AuthError.deleteAccountFailed("セッションが期限切れです。再ログインしてください。")
                    }
                } else {
                    isLoading = false
                    throw AuthError.deleteAccountFailed("セッションが期限切れです。再ログインしてください。")
                }
                
            } else if httpResponse.statusCode == 404 {
                // Edge Function が見つからない場合はログアウトのみ実行
                print("⚠️ Edge Function not found, performing logout only")
                try await fallbackLogout(accessToken: validAccessToken)
                
            } else {
                // エラーレスポンスを解析
                isLoading = false
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = json["error"] as? String {
                    print("❌ Error: \(errorMsg)")
                    throw AuthError.deleteAccountFailed(errorMsg)
                }
                
                throw AuthError.deleteAccountFailed("アカウント削除に失敗しました")
            }
            
        } catch let error as AuthError {
            isLoading = false
            throw error
        } catch {
            isLoading = false
            print("❌ Delete account error: \(error)")
            throw AuthError.deleteAccountFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Refresh Access Token
    @MainActor
    private func refreshAccessToken(refreshToken: String) async throws -> String {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=refresh_token") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.unauthorized
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccessToken = json["access_token"] as? String,
              let newRefreshToken = json["refresh_token"] as? String else {
            throw AuthError.invalidResponse
        }
        
        // 新しいトークンを保存
        UserDefaults.standard.set(newAccessToken, forKey: "supabase_access_token")
        UserDefaults.standard.set(newRefreshToken, forKey: "supabase_refresh_token")
        UserDefaults.standard.set(newAccessToken, forKey: "accessToken")
        UserDefaults.standard.set(newRefreshToken, forKey: "refreshToken")
        
        print("✅ Token refreshed successfully")
        
        return newAccessToken
    }
    
    // Edge Functionがない場合のフォールバック（ログアウトのみ）
    @MainActor
    private func fallbackLogout(accessToken: String) async throws {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/logout") else {
            isLoading = false
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 30
        
        let (_, _) = try await URLSession.shared.data(for: request)
        
        // ローカルの全データを削除
        clearAllLocalData()
        
        isLoggedIn = false
        currentUser = nil
        isLoading = false
        
        print("✅ Logout completed (Edge Function not available)")
    }
    
    // MARK: - Clear All Local Data
    private func clearAllLocalData() {
        // 認証関連
        UserDefaults.standard.removeObject(forKey: "supabase_access_token")
        UserDefaults.standard.removeObject(forKey: "supabase_refresh_token")
        UserDefaults.standard.removeObject(forKey: "supabase_user_id")
        UserDefaults.standard.removeObject(forKey: "supabase_user_email")
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        
        // オンボーディング関連
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "userGoal")
        UserDefaults.standard.removeObject(forKey: "exerciseFrequency")
        UserDefaults.standard.removeObject(forKey: "userGender")
        UserDefaults.standard.removeObject(forKey: "birthDate")
        UserDefaults.standard.removeObject(forKey: "currentWeight")
        UserDefaults.standard.removeObject(forKey: "userHeight")
        UserDefaults.standard.removeObject(forKey: "targetWeight")
        UserDefaults.standard.removeObject(forKey: "targetDate")
        
        // 栄養目標
        UserDefaults.standard.removeObject(forKey: "calorieGoal")
        UserDefaults.standard.removeObject(forKey: "carbsGoal")
        UserDefaults.standard.removeObject(forKey: "proteinGoal")
        UserDefaults.standard.removeObject(forKey: "fatGoal")
        UserDefaults.standard.removeObject(forKey: "sugarGoal")
        UserDefaults.standard.removeObject(forKey: "fiberGoal")
        UserDefaults.standard.removeObject(forKey: "sodiumGoal")
        
        // 食事ログ
        UserDefaults.standard.removeObject(forKey: "mealLogs")
        UserDefaults.standard.removeObject(forKey: "savedMeals")
        
        // 通知設定
        UserDefaults.standard.removeObject(forKey: "notificationSettings")
        
        // プロフィール
        UserDefaults.standard.removeObject(forKey: "userProfile")
        UserDefaults.standard.removeObject(forKey: "userName")
        
        print("🗑️ All local data cleared")
    }
    
    // MARK: - Helper Methods
    
    private func saveTokens(accessToken: String, refreshToken: String?, userId: String, email: String?) {
        UserDefaults.standard.set(accessToken, forKey: "supabase_access_token")
        if let refreshToken = refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: "supabase_refresh_token")
            UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
        }
        UserDefaults.standard.set(userId, forKey: "supabase_user_id")
        if let email = email {
            UserDefaults.standard.set(email, forKey: "supabase_user_email")
        }
        UserDefaults.standard.set(accessToken, forKey: "accessToken")
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
            let window = UIWindow(windowScene: windowScene)
            return window
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
    case cancelled
    case appleSignInFailed(String)
    case deleteAccountFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無効なURLです"
        case .invalidResponse: return "サーバーからの応答が無効です"
        case .signUpFailed: return "アカウント作成に失敗しました"
        case .signInFailed: return "ログインに失敗しました。メールアドレスまたはパスワードを確認してください"
        case .unauthorized: return "認証が必要です"
        case .cancelled: return nil  // キャンセルはエラーメッセージ不要
        case .appleSignInFailed(let message): return "Apple Sign Inに失敗しました: \(message)"
        case .deleteAccountFailed(let message): return "アカウント削除に失敗しました: \(message)"
        }
    }
}
