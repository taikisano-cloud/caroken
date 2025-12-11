import SwiftUI
import AuthenticationServices
import AVFoundation

struct S23_LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var authService = AuthService.shared
    
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
            // 背景を全画面に
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea(.all)
            
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
                
                // iPhone モックアップ
                LoginPhoneMockupView()
                    .padding(.top, 20)
                
                Spacer(minLength: 0)
                
                // ログインセクション
                VStack(spacing: 20) {
                    // ドラッグインジケーター
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(UIColor.systemGray3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 10)
                    
                    socialLoginButtons
                    
                    // 利用規約とプライバシーポリシー
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
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(LoginRoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
                
                // 下部の背景色を埋める
                Color(UIColor.secondarySystemGroupedBackground)
                    .frame(height: 34)
                    .ignoresSafeArea(edges: .bottom)
            }
            
            // ローディングオーバーレイ
            if isSigningIn || authService.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("ログイン中...")
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
            if newValue && !navigateToPaywall {
                print("✅ Auth state changed: isLoggedIn = true, navigating to paywall")
                navigateToPaywall = true
            }
        }
        .onAppear {
            // 既にログイン済みの場合はPaywallへ
            if authService.isLoggedIn && !navigateToPaywall {
                print("✅ Already logged in, navigating to paywall")
                navigateToPaywall = true
            }
        }
    }
    
    // MARK: - Social Login Buttons
    private var socialLoginButtons: some View {
        VStack(spacing: 16) {
            // Appleでサインイン
            SignInWithAppleButton(.signIn) { request in
                // nonceを生成
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
                    // Googleロゴ
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
                    // signInWithGoogleが成功した場合のみここに来る
                    // isLoggedInの変更はonChangeで検知
                }
            } catch AuthError.cancelled {
                // キャンセルはエラー表示しない
                await MainActor.run {
                    isSigningIn = false
                    print("🚫 Google Sign In was cancelled")
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
    
    // MARK: - Apple Sign In (Supabase連携)
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                isSigningIn = true
                
                // IDトークンを取得
                guard let identityTokenData = appleIDCredential.identityToken,
                      let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                    isSigningIn = false
                    errorMessage = "Apple IDトークンの取得に失敗しました"
                    showError = true
                    return
                }
                
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                print("🍎 Apple Sign In - Got ID Token")
                print("   User ID: \(appleIDCredential.user)")
                if let givenName = fullName?.givenName {
                    print("   Name: \(givenName)")
                }
                if let email = email {
                    print("   Email: \(email)")
                }
                
                // SupabaseにIDトークンを送信
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
                            print("✅ Apple Sign In with Supabase completed")
                            navigateToPaywall = true
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
            print("❌ Apple Sign In Error: \(error.localizedDescription)")
            
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
            print("   User canceled")
        case .unknown:
            // シミュレータでのエラーの場合は開発モードでスキップ
            if isDevelopment {
                print("⚠️ Apple Sign In failed on simulator - use Skip button for development")
            }
            errorMessage = "Apple Sign Inでエラーが発生しました。シミュレータでは動作しません。実機でお試しください。"
            showError = true
        case .invalidResponse:
            errorMessage = "サーバーからの応答が無効です。もう一度お試しください。"
            showError = true
        case .notHandled:
            errorMessage = "認証リクエストが処理されませんでした。"
            showError = true
        case .failed:
            errorMessage = "認証に失敗しました。もう一度お試しください。"
            showError = true
        case .notInteractive:
            print("   Not interactive")
        case .matchedExcludedCredential:
            errorMessage = "この資格情報は使用できません。"
            showError = true
        @unknown default:
            errorMessage = "予期しないエラーが発生しました。"
            showError = true
        }
    }
}

// MARK: - iPhone Mockup with Video
struct LoginPhoneMockupView: View {
    var body: some View {
        ZStack {
            // iPhone フレーム（ゴールド）
            RoundedRectangle(cornerRadius: 40)
                .fill(Color(red: 0.85, green: 0.65, blue: 0.2))
                .frame(width: 260, height: 520)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // 内側の黒枠
            RoundedRectangle(cornerRadius: 35)
                .fill(Color.black)
                .frame(width: 248, height: 508)
            
            // 画面エリア（動画表示）
            ZStack {
                // 背景
                Color(UIColor.systemBackground)
                
                // 動画プレイヤー
                LoginVideoPlayerView()
            }
            .frame(width: 236, height: 496)
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
    }
}

// MARK: - Video Player for Login Mockup
struct LoginVideoPlayerView: View {
    @State private var player: AVPlayer?
    @State private var isVideoReady = false
    
    var body: some View {
        ZStack {
            if let player = player {
                LoginVideoPlayer(player: player)
                    .opacity(isVideoReady ? 1 : 0)
            }
            
            // フォールバック（動画が読み込まれるまで）
            if !isVideoReady {
                LoginStaticMockupContent()
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
        
        // 1. Bundle内の動画ファイルを探す
        if let bundleURL = Bundle.main.url(forResource: "OnboardingTest", withExtension: "mp4") {
            videoURL = bundleURL
            print("✅ Login: Video found in Bundle")
        }
        // 2. Assets Catalogから読み込む
        else if let asset = NSDataAsset(name: "OnboardingTest") {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LoginOnboardingTest.mp4")
            do {
                try asset.data.write(to: tempURL)
                videoURL = tempURL
                print("✅ Login: Video loaded from Assets")
            } catch {
                print("❌ Login: Failed to write video: \(error)")
            }
        } else {
            print("⚠️ Login: Video not found, using static mockup")
        }
        
        if let url = videoURL {
            let newPlayer = AVPlayer(url: url)
            newPlayer.isMuted = true
            
            // ループ再生の設定
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: newPlayer.currentItem,
                queue: .main
            ) { _ in
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }
            
            self.player = newPlayer
            
            // 少し遅延してから再生開始
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
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

// MARK: - Static Mockup Content (Fallback)
struct LoginStaticMockupContent: View {
    var body: some View {
        VStack(spacing: 0) {
            // ステータスバー
            HStack {
                Text("22:22")
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 11))
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            
            // ヘッダー
            HStack {
                Text("🐱")
                    .font(.system(size: 18))
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
            
            // 週カレンダー
            HStack(spacing: 6) {
                ForEach(["月", "火", "水", "木", "金", "土", "日"], id: \.self) { day in
                    VStack(spacing: 3) {
                        Text(day)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .stroke(day == "木" ? Color.orange : Color(UIColor.systemGray4), lineWidth: 1)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Text("\(5 + (["月", "火", "水", "木", "金", "土", "日"].firstIndex(of: day) ?? 0))")
                                    .font(.system(size: 9))
                                    .foregroundColor(.primary)
                            )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            
            // カロリーカード
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color(UIColor.systemGray4), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.4)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("摂取カロリー")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("850")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.primary)
                        Text("/2200")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            
            // アドバイスカード
            HStack(spacing: 6) {
                Text("🐱")
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("いい感じだにゃ！🐱")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                    Text("バランスよく食べられてるよ✨")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding(10)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            
            // 栄養素カード
            HStack(spacing: 6) {
                LoginMockNutrient(emoji: "🥩", value: "45", target: "100", name: "たんぱく質")
                LoginMockNutrient(emoji: "🥑", value: "30", target: "60", name: "脂質")
                LoginMockNutrient(emoji: "🍚", value: "120", target: "250", name: "炭水化物")
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            
            Spacer()
            
            // タブバー
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 16))
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
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Spacer()
                
                VStack(spacing: 2) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16))
                    Text("進捗")
                        .font(.system(size: 8))
                }
                .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.bottom, 8)
        }
        .frame(width: 236, height: 496)
    }
}

// MARK: - ミニ栄養素カード
struct LoginMockNutrient: View {
    let emoji: String
    let value: String
    let target: String
    let name: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 16))
            Text("\(value)/\(target)g")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.primary)
            Text(name)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
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
