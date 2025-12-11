import SwiftUI

struct LaunchScreenView: View {
    @State private var showLoadingIndicator: Bool = false
    
    var body: some View {
        ZStack {
            // 背景色
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // キャラクター画像（大きく表示）
                Image("caloken_character")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                
                // ローディングインジケーター（常にスペースを確保）
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    .scaleEffect(3.0)
                    .opacity(showLoadingIndicator ? 1.0 : 0.0)
            }
        }
        .onAppear {
            // 少し遅れてローディングインジケーターを表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showLoadingIndicator = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
