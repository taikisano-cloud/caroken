import SwiftUI

@main
struct CalokenApp: App {
    @State private var isLoading: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // メインコンテンツ（既存のContentViewを使用）
                ContentView()
                    .opacity(isLoading ? 0 : 1)
                
                // ローディング画面
                if isLoading {
                    LaunchScreenView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                // 初期化処理（データ読み込みなど）
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
