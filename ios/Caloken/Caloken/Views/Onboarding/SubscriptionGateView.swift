import SwiftUI

/// ホーム画面を表示する前に課金状態をチェックするゲートView
/// 課金していない場合はPaywallを表示する
struct SubscriptionGateView<Content: View>: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall: Bool = false
    @State private var hasChecked: Bool = false
    
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ZStack {
            if hasChecked {
                if subscriptionManager.isSubscribed {
                    // 課金済み → コンテンツを表示
                    content()
                } else {
                    // 未課金 → Paywallを表示
                    NavigationStack {
                        S51_PaywallView()
                    }
                }
            } else {
                // チェック中
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("確認中...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .task {
            await subscriptionManager.checkSubscriptionStatus()
            hasChecked = true
        }
        // 課金状態の変化を監視
        .onChange(of: subscriptionManager.isSubscribed) { _, newValue in
            if !newValue && hasChecked {
                // 課金が切れた場合（アプリ使用中に期限切れなど）
                print("⚠️ Subscription expired, showing paywall")
            }
        }
    }
}

#Preview {
    SubscriptionGateView {
        Text("Home Content")
    }
}
