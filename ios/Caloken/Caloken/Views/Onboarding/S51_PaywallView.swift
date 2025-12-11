import SwiftUI
import StoreKit
import AVFoundation

struct S51_PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // ログイン状態を@AppStorageで管理
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    @State private var selectedPlan: PaywallSubscriptionPlan = .yearly
    @State private var isLoading: Bool = false
    @State private var navigateToTerms: Bool = false
    @State private var navigateToPrivacy: Bool = false
    @State private var showPurchaseError: Bool = false
    @State private var errorMessage: String = ""
    @State private var hasAutoStartedPurchase: Bool = false
    
    // 開発モード（本番リリース前にfalseに変更）
    private let isDevelopment = true
    
    var body: some View {
        ZStack {
            // 背景を全画面に
            Color(UIColor.systemBackground)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // 開発用スキップボタン
                if isDevelopment {
                    HStack {
                        Spacer()
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                    }
                }
                
                // ヘッダー（シンプルに）
                Text("目標達成を加速させるために\nカロ研をアンロックしましょう")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.top, isDevelopment ? 4 : 16)
                
                Spacer()
                
                // iPhoneモックアップ（少し小さめ）
                PaywallPhoneMockupView()
                
                Spacer()
                
                // プラン選択
                VStack(spacing: 8) {
                    // 年額プラン
                    PaywallCompactPlanCard(
                        plan: .yearly,
                        isSelected: selectedPlan == .yearly
                    ) {
                        selectedPlan = .yearly
                    }
                    
                    // 月額プラン
                    PaywallCompactPlanCard(
                        plan: .monthly,
                        isSelected: selectedPlan == .monthly
                    ) {
                        selectedPlan = .monthly
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 16)
                
                // 続けるボタン
                Button {
                    purchase()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.orange)
                            .cornerRadius(26)
                    } else {
                        Text("7日間無料で始める")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.orange)
                            .cornerRadius(26)
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal, 20)
                
                // 価格詳細
                Text("無料期間後 \(selectedPlan.price)/\(selectedPlan.period)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                // フッターリンク
                HStack(spacing: 20) {
                    Button {
                        navigateToPrivacy = true
                    } label: {
                        Text("プライバシー")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        restorePurchases()
                    } label: {
                        Text("購入を復元")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        navigateToTerms = true
                    } label: {
                        Text("利用規約")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $navigateToTerms) {
            NavigationStack {
                S27_7_TermsOfServiceView()
            }
        }
        .sheet(isPresented: $navigateToPrivacy) {
            NavigationStack {
                S27_8_PrivacyPolicyView()
            }
        }
        .alert("購入エラー", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // 画面表示時に自動で年額プランの決済を開始
            if !hasAutoStartedPurchase {
                hasAutoStartedPurchase = true
                
                // 少し遅延させてUIが表示されてから決済ダイアログを出す
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 既に課金済みかチェック
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()
                        if subscriptionManager.isSubscribed {
                            print("✅ Already subscribed, going to home")
                            completePurchase()
                        } else {
                            // 未課金なら自動で年額プラン購入を開始
                            purchase()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 購入完了処理
    private func completePurchase() {
        withAnimation {
            isLoggedIn = true
        }
    }
    
    private func purchase() {
        isLoading = true
        print("💳 Starting purchase for plan: \(selectedPlan.productId)")
        
        Task {
            do {
                let success = try await subscriptionManager.purchase(productId: selectedPlan.productId)
                
                await MainActor.run {
                    isLoading = false
                    if success {
                        completePurchase()
                    }
                }
            } catch SubscriptionError.productNotFound {
                await MainActor.run {
                    isLoading = false
                    print("⚠️ Product not found: \(selectedPlan.productId)")
                    
                    // 開発モードではスキップ
                    if isDevelopment {
                        print("🔧 Development mode: skipping purchase")
                        completePurchase()
                    } else {
                        errorMessage = "商品が見つかりませんでした"
                        showPurchaseError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Purchase error: \(error)")
                    
                    // 開発モードではスキップ
                    if isDevelopment {
                        print("🔧 Development mode: skipping after error")
                        completePurchase()
                    } else {
                        errorMessage = error.localizedDescription
                        showPurchaseError = true
                    }
                }
            }
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        print("🔄 Restoring purchases...")
        
        Task {
            do {
                let restored = try await subscriptionManager.restorePurchases()
                
                await MainActor.run {
                    isLoading = false
                    if restored {
                        print("✅ Purchases restored!")
                        completePurchase()
                    } else {
                        print("⚠️ No purchases to restore")
                        // 開発モードではスキップ
                        if isDevelopment {
                            completePurchase()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Restore error: \(error)")
                }
            }
        }
    }
}

// MARK: - サブスクリプションプラン
enum PaywallSubscriptionPlan: String, CaseIterable {
    case yearly
    case monthly
    
    var title: String {
        switch self {
        case .yearly: return "年額プラン"
        case .monthly: return "月額プラン"
        }
    }
    
    var price: String {
        switch self {
        case .yearly: return "¥6,900"
        case .monthly: return "¥980"
        }
    }
    
    var period: String {
        switch self {
        case .yearly: return "年"
        case .monthly: return "月"
        }
    }
    
    var subtitle: String {
        switch self {
        case .yearly: return "7日間無料！その後 1日あたり19円"
        case .monthly: return "7日間無料！"
        }
    }
    
    var badge: String? {
        switch self {
        case .yearly: return "👑 人気No.1"
        case .monthly: return nil
        }
    }
    
    var productId: String {
        switch self {
        case .yearly: return "com.caloken.subscription.yearly"
        case .monthly: return "com.caloken.subscription.monthly"
        }
    }
}

// MARK: - コンパクトプランカード
struct PaywallCompactPlanCard: View {
    let plan: PaywallSubscriptionPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    // バッジ
                    if let badge = plan.badge {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                    
                    // タイトル
                    Text(plan.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // サブタイトル
                    Text(plan.subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // 価格
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text("/ \(plan.period)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                // チェックマーク
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .orange : Color(UIColor.systemGray3))
                    .padding(.leading, 6)
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color(UIColor.separator), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - iPhone Mockup with Video (黒フレーム・少し小さめ)
struct PaywallPhoneMockupView: View {
    var body: some View {
        ZStack {
            // 外側フレーム（黒）
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.black)
                .frame(width: 240, height: 480)
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            
            // 内側フレーム（ダークグレー - ベゼル）
            RoundedRectangle(cornerRadius: 37)
                .fill(Color(white: 0.15))
                .frame(width: 232, height: 472)
            
            // 画面部分
            ZStack {
                Color(UIColor.systemBackground)
                PaywallVideoPlayerView()
            }
            .frame(width: 218, height: 458)
            .clipShape(RoundedRectangle(cornerRadius: 33))
            
            // ダイナミックアイランド
            Capsule()
                .fill(Color.black)
                .frame(width: 76, height: 24)
                .offset(y: -215)
        }
    }
}

// MARK: - 動画プレイヤー
struct PaywallVideoPlayerView: View {
    @State private var player: AVPlayer?
    @State private var isVideoReady = false
    
    var body: some View {
        ZStack {
            if let player = player {
                PaywallPlayerRepresentable(player: player)
                    .opacity(isVideoReady ? 1 : 0)
            }
            
            if !isVideoReady {
                PaywallStaticContent()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func setupPlayer() {
        var videoURL: URL?
        
        // Bundle内の動画ファイルを探す
        if let bundleURL = Bundle.main.url(forResource: "onboarding", withExtension: "mp4") {
            videoURL = bundleURL
            print("✅ Paywall: Video found in Bundle")
        }
        // Assets Catalogから読み込む
        else if let asset = NSDataAsset(name: "onboarding") {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("PaywallVideo.mp4")
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try asset.data.write(to: tempURL)
                videoURL = tempURL
                print("✅ Paywall: Video loaded from Assets")
            } catch {
                print("❌ Paywall: Failed to write video: \(error)")
            }
        } else {
            print("⚠️ Paywall: Video not found, using static content")
        }
        
        if let url = videoURL {
            let newPlayer = AVPlayer(url: url)
            newPlayer.isMuted = true
            
            // ループ再生
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: newPlayer.currentItem,
                queue: .main
            ) { _ in
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }
            
            self.player = newPlayer
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                newPlayer.play()
                withAnimation(.easeIn(duration: 0.3)) {
                    isVideoReady = true
                }
            }
        }
    }
}

// MARK: - AVPlayer UIViewRepresentable
struct PaywallPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = PaywallPlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class PaywallPlayerUIView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

// MARK: - 静的フォールバックコンテンツ
struct PaywallStaticContent: View {
    var body: some View {
        VStack(spacing: 0) {
            // ステータスバー
            HStack {
                Text("22:22")
                    .font(.system(size: 10, weight: .medium))
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 10))
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 38)
            
            // ヘッダー
            HStack {
                Text("🐱")
                    .font(.system(size: 16))
                Text("カロ研")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
                Spacer()
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            
            Spacer()
            
            // メインコンテンツ
            ZStack {
                Circle()
                    .stroke(Color(UIColor.systemGray4), lineWidth: 8)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: 0.4)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.orange)
            }
            
            Text("850 / 2200 kcal")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .padding(.top, 10)
            
            Spacer()
            
            // タブバー
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 15))
                    Text("ホーム")
                        .font(.system(size: 8))
                }
                .foregroundColor(.orange)
                
                Spacer()
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Spacer()
                
                VStack(spacing: 2) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 15))
                    Text("進捗")
                        .font(.system(size: 8))
                }
                .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.bottom, 6)
        }
    }
}

#Preview {
    NavigationStack {
        S51_PaywallView()
    }
}
