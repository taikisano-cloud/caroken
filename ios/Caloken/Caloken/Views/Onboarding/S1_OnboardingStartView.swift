import SwiftUI
import AVKit

struct S1_OnboardingStartView: View {
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                // コンテンツ
                VStack(spacing: 0) {
                    Spacer()
                    
                    // iPhone モックアップ
                    WelcomePhoneMockupView()
                    
                    Spacer()
                    
                    // ボタンエリア
                    VStack(spacing: 12) {
                        // キャッチコピー
                        Text("カロリー管理を手軽に")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.bottom, 16)
                        
                        // はじめるボタン
                        NavigationLink {
                            S2_OnboardingFlowView()
                        } label: {
                            Text("はじめる")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(30)
                        }
                        
                        // サインインリンク → S23_LoginViewへ
                        NavigationLink {
                            S23_LoginView()
                        } label: {
                            Text("すでにアカウントをお持ちの方")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .underline()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - iPhone Mockup with Video (黒フレーム)
struct WelcomePhoneMockupView: View {
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
                WelcomeVideoPlayerView()
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

// MARK: - Video Player for Welcome
struct WelcomeVideoPlayerView: View {
    @State private var player: AVPlayer?
    @State private var isVideoReady = false
    
    var body: some View {
        ZStack {
            if let player = player {
                WelcomeVideoPlayer(player: player)
                    .opacity(isVideoReady ? 1 : 0)
            }
            
            if !isVideoReady {
                WelcomeStaticMockupContent()
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
        
        // Bundle内のファイルを探す
        if let bundleURL = Bundle.main.url(forResource: "onboarding", withExtension: "mp4") {
            videoURL = bundleURL
            debugPrint("✅ Welcome: Video found in Bundle")
        } else if let asset = NSDataAsset(name: "onboarding") {
            // Assets Catalogから取得
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("WelcomeOnboarding.mp4")
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try asset.data.write(to: tempURL)
                videoURL = tempURL
                debugPrint("✅ Welcome: Video loaded from Assets")
            } catch {
                debugPrint("❌ Welcome: Failed to write video: \(error)")
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

struct WelcomeVideoPlayer: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = WelcomePlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class WelcomePlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

// MARK: - Static Mockup Content (フォールバック用)
struct WelcomeStaticMockupContent: View {
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
            .padding(.bottom, 12)
        }
    }
}

#Preview {
    S1_OnboardingStartView()
}
