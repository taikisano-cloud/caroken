import SwiftUI
import StoreKit
import AVFoundation

struct S51_PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // ログイン状態を@AppStorageで管理
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    @State private var selectedPlan: PaywallSubscriptionPlan = .yearly
    @State private var isLoading: Bool = false
    @State private var navigateToTerms: Bool = false
    @State private var navigateToPrivacy: Bool = false
    @State private var showPurchaseError: Bool = false
    
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
                        Button("スキップ") {
                            completePurchase()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                    }
                }
                
                // ヘッダー（コンパクト）
                VStack(spacing: 6) {
                    Text("目標達成を加速させるために\nカロ研をアンロックしましょう")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                    
                    // 無料トライアルバナー
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text("7日間無料でお試し")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(14)
                    
                    // 特典
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text("契約の縛りなし - いつでもキャンセル可能")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, isDevelopment ? 0 : 16)
                
                // iPhoneモックアップ（動画付き）
                PaywallVideoMockupView()
                    .padding(.top, 8)
                
                Spacer(minLength: 20)
                
                // プラン選択（コンパクト）
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
                
                Spacer(minLength: 16)
                
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
            Text("購入処理中にエラーが発生しました。もう一度お試しください。")
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
                let productIds = [selectedPlan.productId]
                print("💳 Fetching products: \(productIds)")
                let products = try await Product.products(for: productIds)
                print("💳 Products found: \(products.count)")
                
                if let product = products.first {
                    print("💳 Purchasing product: \(product.displayName) - \(product.displayPrice)")
                    let result = try await product.purchase()
                    
                    switch result {
                    case .success(let verification):
                        print("💳 Purchase success, verifying...")
                        switch verification {
                        case .verified(_):
                            print("✅ Purchase verified!")
                            await MainActor.run {
                                isLoading = false
                                completePurchase()
                            }
                        case .unverified(_, _):
                            print("❌ Purchase unverified")
                            await MainActor.run {
                                isLoading = false
                                showPurchaseError = true
                            }
                        }
                    case .userCancelled:
                        print("🚫 Purchase cancelled by user")
                        await MainActor.run {
                            isLoading = false
                        }
                    case .pending:
                        print("⏳ Purchase pending")
                        await MainActor.run {
                            isLoading = false
                        }
                    @unknown default:
                        print("❓ Unknown purchase result")
                        await MainActor.run {
                            isLoading = false
                        }
                    }
                } else {
                    print("⚠️ No products found for ID: \(selectedPlan.productId)")
                    await MainActor.run {
                        isLoading = false
                        // 商品が見つからない場合は開発中としてスキップ
                        if isDevelopment {
                            print("🔧 Development mode: skipping purchase")
                            completePurchase()
                        } else {
                            showPurchaseError = true
                        }
                    }
                }
            } catch {
                print("❌ Purchase error: \(error)")
                await MainActor.run {
                    isLoading = false
                    // 開発中はエラーでもスキップ可能
                    if isDevelopment {
                        print("🔧 Development mode: skipping after error")
                        completePurchase()
                    } else {
                        showPurchaseError = true
                    }
                }
            }
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        
        Task {
            do {
                for await result in Transaction.currentEntitlements {
                    if case .verified(let transaction) = result {
                        if transaction.productID == PaywallSubscriptionPlan.yearly.productId ||
                           transaction.productID == PaywallSubscriptionPlan.monthly.productId {
                            await MainActor.run {
                                isLoading = false
                                completePurchase()
                            }
                            return
                        }
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                    // 復元するものがない場合もスキップ（開発中）
                    if isDevelopment {
                        completePurchase()
                    }
                }
            } catch {
                await MainActor.run {
                    print("Restore error: \(error)")
                    isLoading = false
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

// MARK: - 動画付きiPhoneモックアップ
struct PaywallVideoMockupView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // iPhone フレーム
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.orange)
                .frame(width: 150, height: 300)
                .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .frame(width: 142, height: 292)
            
            // 動画コンテンツ
            PaywallVideoPlayerView()
                .frame(width: 136, height: 286)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - 動画プレイヤー
struct PaywallVideoPlayerView: View {
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            // フォールバック背景
            Color.black
            
            if let player = player {
                PaywallPlayerRepresentable(player: player)
            } else {
                // 動画がない場合のフォールバック
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
        if let bundleURL = Bundle.main.url(forResource: "OnboardingTest", withExtension: "mp4") {
            videoURL = bundleURL
            print("✅ Paywall: Video found in Bundle")
        }
        // Assets Catalogから読み込む
        else if let asset = NSDataAsset(name: "OnboardingTest") {
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
            newPlayer.play()
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
        view.backgroundColor = .black
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
        VStack(spacing: 8) {
            // ステータスバー
            HStack {
                Text("22:22")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 8))
                .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            
            // ヘッダー
            HStack {
                Text("🐱")
                    .font(.system(size: 12))
                Text("カロ研")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
                Spacer()
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // カロリーリング
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: 0.4)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("850")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text("/2200")
                        .font(.system(size: 6))
                        .foregroundColor(.gray)
                }
            }
            
            // メッセージ
            HStack(spacing: 4) {
                Text("🐱")
                    .font(.system(size: 10))
                Text("いい感じだにゃ！")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(10)
            
            Spacer()
            
            // タブバー
            HStack {
                VStack(spacing: 2) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 10))
                    Text("ホーム")
                        .font(.system(size: 6))
                }
                .foregroundColor(.white)
                
                Spacer()
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Spacer()
                
                VStack(spacing: 2) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 10))
                    Text("進捗")
                        .font(.system(size: 6))
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
    }
}

#Preview {
    NavigationStack {
        S51_PaywallView()
    }
}
