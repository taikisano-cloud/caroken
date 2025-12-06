import SwiftUI

@main
struct CalokenApp: App {
    @State private var isLoading: Bool = true
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // メインコンテンツ（ログイン状態で切り替え）
                Group {
                    if isLoggedIn {
                        // ログイン済み → メイン画面
                        ContentView()
                    } else {
                        // 未ログイン → S1（オンボーディング/ログイン選択画面）
                        S1_OnboardingStartView()
                    }
                }
                .opacity(isLoading ? 0 : 1)
                
                // ローディング画面
                if isLoading {
                    LaunchScreenView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isLoggedIn)
            .onAppear {
                initializeApp()
            }
        }
    }
    
    private func initializeApp() {
        Task {
            // 実際のデータ読み込み処理をここに追加
            // await loadUserData()
            // await checkAuthStatus()
            
            // 最低1.5秒は表示
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            // メイン画面へ遷移
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }
}
