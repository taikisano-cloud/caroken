import SwiftUI
import AVKit

struct S1_OnboardingStartView: View {
    @State private var videoLoadError: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景（動画またはフォールバック）
                if videoLoadError {
                    // フォールバック背景
                    Color(UIColor.systemBackground)
                        .ignoresSafeArea()
                } else {
                    // 背景動画
                    VideoPlayerView(videoName: "OnboardingTest", onError: {
                        videoLoadError = true
                    })
                    .ignoresSafeArea()
                }
                
                // オーバーレイ（グラデーション）- 動画がある場合のみ
                if !videoLoadError {
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
                }
                
                // コンテンツ
                VStack {
                    Spacer()
                    
                    // ボタンエリア
                    VStack(spacing: 12) {
                        // キャッチコピー
                        Text("カロリー管理を手軽に")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(videoLoadError ? .primary : .white)
                            .padding(.bottom, 20)
                        
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
                                .foregroundColor(videoLoadError ? .secondary : .white.opacity(0.9))
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
        backgroundColor = UIColor.systemBackground
        setupPlayer(videoName: videoName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlayer(videoName: String) {
        var videoURL: URL?
        
        // 1. まずBundle内のファイルを探す（複数の拡張子を試す）
        let extensions = ["mp4", "mov", "m4v", "MP4", "MOV", "M4V"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: videoName, withExtension: ext) {
                videoURL = url
                print("✅ Video found in Bundle: \(videoName).\(ext)")
                break
            }
        }
        
        // 2. Assets Catalogから動画を取得（iOS 17+対応）
        if videoURL == nil {
            // Assets内のData Setとして動画がある場合
            if let asset = NSDataAsset(name: videoName) {
                // 一時ファイルに書き出して再生
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(videoName).mp4")
                do {
                    // 既存のファイルがあれば削除
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try asset.data.write(to: tempURL)
                    videoURL = tempURL
                    print("✅ Video loaded from Assets: \(videoName)")
                } catch {
                    print("❌ Failed to write video from Assets: \(error)")
                }
            }
        }
        
        // 3. ファイルが見つからない場合
        guard let url = videoURL else {
            print("❌ Video file not found: \(videoName)")
            print("   - Checked Bundle for: \(extensions.map { "\(videoName).\($0)" }.joined(separator: ", "))")
            print("   - Checked Assets Catalog")
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
        
        // エラー監視
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            print("❌ Video playback failed")
            self?.onError?()
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
