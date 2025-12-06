import SwiftUI
import AVKit

struct S1_OnboardingStartView: View {
    @State private var navigateToOnboarding: Bool = false
    @State private var navigateToSignIn: Bool = false
    @State private var videoLoadError: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景（動画またはフォールバック）
                if videoLoadError {
                    // フォールバック背景
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.2, blue: 0.25),
                            Color(red: 0.1, green: 0.1, blue: 0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                } else {
                    // 背景動画
                    VideoPlayerView(videoName: "OnboardingTest", onError: {
                        videoLoadError = true
                    })
                    .ignoresSafeArea()
                }
                
                // オーバーレイ（グラデーション）
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.1),
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // コンテンツ
                VStack {
                    Spacer()
                    
                    // ボタンエリア
                    VStack(spacing: 12) {
                        // キャッチコピー
                        Text("カロリー管理を手軽に")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                        
                        // はじめるボタン
                        Button {
                            navigateToOnboarding = true
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
                        Button {
                            navigateToSignIn = true
                        } label: {
                            Text("すでにアカウントをお持ちの方")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.9))
                                .underline()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
            .navigationDestination(isPresented: $navigateToOnboarding) {
                S2_OnboardingFlowView()
            }
            .navigationDestination(isPresented: $navigateToSignIn) {
                S23_LoginView()
            }
        }
    }
}

// MARK: - ビデオプレイヤー（ループ再生）
struct VideoPlayerView: UIViewRepresentable {
    let videoName: String
    var onError: (() -> Void)?
    
    func makeUIView(context: Context) -> UIView {
        let view = LoopingVideoPlayerUIView(videoName: videoName, onError: onError)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class LoopingVideoPlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var onError: (() -> Void)?
    
    init(videoName: String, onError: (() -> Void)?) {
        self.onError = onError
        super.init(frame: .zero)
        backgroundColor = .darkGray
        setupPlayer(videoName: videoName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(videoName: String) {
        // 複数の拡張子を試す
        let extensions = ["mp4", "mov", "m4v", "MP4", "MOV", "M4V"]
        var videoURL: URL?
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: videoName, withExtension: ext) {
                videoURL = url
                print("✅ Video found: \(videoName).\(ext)")
                break
            }
        }
        
        guard let url = videoURL else {
            print("❌ Video file not found: \(videoName)")
            DispatchQueue.main.async {
                self.onError?()
            }
            return
        }
        
        // AVPlayerを使用
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = true
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
        
        // ループ再生の設定
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        player?.play()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.pause()
    }
}

#Preview {
    S1_OnboardingStartView()
}

