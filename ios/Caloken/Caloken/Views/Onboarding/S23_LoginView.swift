import SwiftUI
import AuthenticationServices
import AVFoundation

struct S23_LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var authService = AuthService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // ログイン状態を@AppStorageで管理（課金済みでホームに入れる状態）
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    @State private var navigateToPaywall: Bool = false
    @State private var navigateToTerms: Bool = false
    @State private var navigateToPrivacy: Bool = false
    @State private var isSigningIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    // Apple Sign In用
    @State private var currentNonce: String = ""
    
    // 開発用スキップ
    private let isDevelopment = true
    
    var body: some View {
        ZStack {
            // 背景色
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // コンテンツレイヤー
            VStack(spacing: 0) {
                // カスタム戻るボタン
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(UIColor.systemGray5))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                Spacer()
                
                // iPhone モックアップ - 中央に配置
                LoginPhoneMockupView()
                    .padding(.bottom, 8)
                
                Spacer()
                
                // ログインセクション - 画面下部に固定
                VStack(spacing: 16) {
                    // ドラッグインジケーター
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(UIColor.systemGray3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 12)
                    
                    socialLoginButtons
                        .padding(.top, 4)
                    
                    // 利用規約とプライバシーポリシー
                    termsSection
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(LoginRoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
            }
            
            // ローディングオーバーレイ
            if isSigningIn || authService.isLoading || subscriptionManager.isChecking {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text(subscriptionManager.isChecking ? "確認中..." : "ログイン中...")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToPaywall) {
            S51_PaywallView()
        }
        .navigationDestination(isPresented: $navigateToTerms) {
            S27_7_TermsOfServiceView()
        }
        .navigationDestination(isPresented: $navigateToPrivacy) {
            S27_8_PrivacyPolicyView()
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: authService.isLoggedIn) { _, newValue in
            if newValue {
                debugPrint("✅ Auth state changed: isLoggedIn = true")
                checkSubscriptionAndNavigate()
            }
        }
        .onAppear {
            if authService.isLoggedIn {
                debugPrint("✅ Already logged in, checking subscription...")
                checkSubscriptionAndNavigate()
            }
        }
    }
    
    // MARK: - サブスクリプション確認して遷移
    private func checkSubscriptionAndNavigate() {
        Task {
            await subscriptionManager.checkSubscriptionStatus()
            
            await MainActor.run {
                if subscriptionManager.isSubscribed {
                    // 課金済み → ホームへ直行
                    debugPrint("✅ User is subscribed, going to home")
                    isLoggedIn = true
                } else {
                    // 未課金 → Paywallへ
                    debugPrint("⚠️ User is not subscribed, showing paywall")
                    navigateToPaywall = true
                }
            }
        }
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 4) {
            Text("続行することで、カロ研の")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Button {
                    navigateToTerms = true
                } label: {
                    Text("利用規約")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                
                Text("と")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Button {
                    navigateToPrivacy = true
                } label: {
                    Text("プライバシーポリシー")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                
                Text("に同意します")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, safeAreaBottomInset > 0 ? safeAreaBottomInset : 16)
    }
    
    // Safe Area の下部インセットを取得
    private var safeAreaBottomInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
    
    // MARK: - Social Login Buttons
    private var socialLoginButtons: some View {
        VStack(spacing: 16) {
            // Appleでサインイン
            SignInWithAppleButton(.signIn) { request in
                currentNonce = authService.generateNonce()
                request.requestedScopes = [.fullName, .email]
                request.nonce = authService.sha256(currentNonce)
            } onCompletion: { result in
                handleAppleSignIn(result: result)
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 54)
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .disabled(isSigningIn)
            
            // Googleでサインイン
            Button {
                signInWithGoogle()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                        
                        Text("G")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .yellow, .green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("Googleで続ける")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            .disabled(isSigningIn)
        }
    }
    
    // MARK: - Google Sign In
    private func signInWithGoogle() {
        isSigningIn = true
        Task {
            do {
                try await authService.signInWithGoogle()
                await MainActor.run {
                    isSigningIn = false
                }
            } catch AuthError.cancelled {
                await MainActor.run {
                    isSigningIn = false
                    debugPrint("🚫 Google Sign In was cancelled")
                }
            } catch {
                await MainActor.run {
                    isSigningIn = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Apple Sign In
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                isSigningIn = true
                
                guard let identityTokenData = appleIDCredential.identityToken,
                      let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                    isSigningIn = false
                    errorMessage = "Apple IDトークンの取得に失敗しました"
                    showError = true
                    return
                }
                
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                debugPrint("🍎 Apple Sign In - Got ID Token")
                
                Task {
                    do {
                        try await authService.signInWithApple(
                            idToken: identityToken,
                            nonce: currentNonce,
                            fullName: fullName,
                            email: email
                        )
                        
                        await MainActor.run {
                            isSigningIn = false
                            debugPrint("✅ Apple Sign In with Supabase completed")
                        }
                    } catch {
                        await MainActor.run {
                            isSigningIn = false
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }
            
        case .failure(let error):
            debugPrint("❌ Apple Sign In Error: \(error.localizedDescription)")
            
            if let authError = error as? ASAuthorizationError {
                handleAuthorizationError(authError)
            } else {
                errorMessage = "サインインに失敗しました: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func handleAuthorizationError(_ authError: ASAuthorizationError) {
        switch authError.code {
        case .canceled:
            debugPrint("   User canceled")
        case .unknown:
            if isDevelopment {
                debugPrint("⚠️ Apple Sign In failed on simulator")
            }
            errorMessage = "Apple Sign Inでエラーが発生しました。シミュレータでは動作しません。"
            showError = true
        case .invalidResponse:
            errorMessage = "サーバーからの応答が無効です。"
            showError = true
        case .notHandled:
            errorMessage = "認証リクエストが処理されませんでした。"
            showError = true
        case .failed:
            errorMessage = "認証に失敗しました。"
            showError = true
        case .notInteractive:
            debugPrint("   Not interactive")
        case .matchedExcludedCredential:
            errorMessage = "この資格情報は使用できません。"
            showError = true
        @unknown default:
            errorMessage = "予期しないエラーが発生しました。"
            showError = true
        }
    }
}

// MARK: - iPhone Mockup with Video (黒フレーム)
struct LoginPhoneMockupView: View {
    var body: some View {
        ZStack {
            // 外側フレーム（黒）
            RoundedRectangle(cornerRadius: 45)
                .fill(Color.black)
                .frame(width: 280, height: 560)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // 内側フレーム（ダークグレー - ベゼル）
            RoundedRectangle(cornerRadius: 42)
                .fill(Color(white: 0.15))
                .frame(width: 272, height: 552)
            
            // 画面部分
            ZStack {
                Color(UIColor.systemBackground)
                LoginVideoPlayerView()
            }
            .frame(width: 256, height: 536)
            .clipShape(RoundedRectangle(cornerRadius: 38))
            
            // ダイナミックアイランド
            Capsule()
                .fill(Color.black)
                .frame(width: 90, height: 28)
                .offset(y: -252)
        }
    }
}

// MARK: - Video Player
struct LoginVideoPlayerView: View {
    @State private var player: AVPlayer?
    @State private var isVideoReady = false
    
    var body: some View {
        ZStack {
            if let player = player {
                LoginVideoPlayer(player: player)
                    .opacity(isVideoReady ? 1 : 0)
            }
            
            if !isVideoReady {
                LoginStaticMockupContent()
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func setupPlayer() {
        var videoURL: URL?
        
        // Bundle内のファイルを探す（動画名: onboarding）
        if let bundleURL = Bundle.main.url(forResource: "onboarding", withExtension: "mp4") {
            videoURL = bundleURL
            debugPrint("✅ Login: Video found in Bundle")
        } else if let asset = NSDataAsset(name: "onboarding") {
            // Assets Catalogから取得
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LoginOnboarding.mp4")
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try asset.data.write(to: tempURL)
                videoURL = tempURL
                debugPrint("✅ Login: Video loaded from Assets")
            } catch {
                debugPrint("❌ Login: Failed to write video: \(error)")
            }
        }
        
        if let url = videoURL {
            let newPlayer = AVPlayer(url: url)
            newPlayer.isMuted = true
            
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

struct LoginVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = LoginPlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class LoginPlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

// MARK: - Static Mockup Content
struct LoginStaticMockupContent: View {
    var body: some View {
        VStack(spacing: 0) {
            // ステータスバー
            HStack {
                Text("22:22")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 12))
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 45)
            
            // ヘッダー
            HStack {
                Text("🐱")
                    .font(.system(size: 20))
                Text("カロ研")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                Spacer()
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Spacer()
            
            // メインコンテンツ
            ZStack {
                Circle()
                    .stroke(Color(UIColor.systemGray4), lineWidth: 10)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: 0.4)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
            }
            
            Text("850 / 2200 kcal")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(.top, 12)
            
            Spacer()
            
            // タブバー
            HStack {
                Spacer()
                VStack(spacing: 3) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 18))
                    Text("ホーム")
                        .font(.system(size: 9))
                }
                .foregroundColor(.orange)
                
                Spacer()
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Spacer()
                
                VStack(spacing: 3) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18))
                    Text("進捗")
                        .font(.system(size: 9))
                }
                .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
}

// MARK: - 角丸Shape
struct LoginRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        S23_LoginView()
    }
}
