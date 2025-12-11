import SwiftUI
import UserNotifications

@main
struct CalokenApp: App {
    // ログイン状態を管理（課金完了後にtrue）
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    // アプリのライフサイクルを監視
    @Environment(\.scenePhase) private var scenePhase
    
    // AppDelegateを連携
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
        // scenePhaseの変化を監視
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // アプリがアクティブになったらバッジをクリア
                NotificationManager.shared.clearBadge()
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

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 通知のデリゲート設定
        UNUserNotificationCenter.current().delegate = self
        
        // バッジをクリア
        NotificationManager.shared.clearBadge()
        
        return true
    }
    
    // フォアグラウンドで通知を受け取った時
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでもバナー表示
        completionHandler([.banner, .sound, .badge])
    }
    
    // 通知をタップした時
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 通知の種類に応じて画面遷移などを行う
        let identifier = response.notification.request.identifier
        
        if identifier.contains("meal") {
            // 食事記録画面に遷移
            NotificationCenter.default.post(name: .openMealRecord, object: nil)
        } else if identifier.contains("weight") {
            // 体重記録画面に遷移
            NotificationCenter.default.post(name: .openWeightRecord, object: nil)
        }
        
        completionHandler()
    }
}

// MARK: - 通知名の定義
extension Notification.Name {
    static let openMealRecord = Notification.Name("openMealRecord")
    static let openWeightRecord = Notification.Name("openWeightRecord")
}
