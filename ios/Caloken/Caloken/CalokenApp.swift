import SwiftUI

@main
struct CalokenApp: App {
    // ログイン状態を管理（課金完了後にtrue）
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    // ログイン済み → メイン画面
                    ContentView()
                } else {
                    // 未ログイン → オンボーディング
                    S1_OnboardingStartView()
                }
            }
            .onOpenURL { url in
                // Google OAuth コールバック処理
                handleOAuthCallback(url: url)
            }
        }
    }
    
    // MARK: - OAuth Callback Handler
    private func handleOAuthCallback(url: URL) {
        // カスタムURLスキーム: com.stellacreation.caloken://login-callback
        if url.scheme == "com.stellacreation.caloken" && url.host == "login-callback" {
            Task {
                await AuthService.shared.handleOAuthCallback(url: url)
            }
        }
    }
}
