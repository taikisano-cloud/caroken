import SwiftUI
import UIKit

// MARK: - スワイプバックジェスチャーを有効化するView Extension
extension View {
    /// カスタム戻るボタン使用時もスワイプで戻れるようにする
    func enableSwipeBack() -> some View {
        self.background(SwipeBackGestureEnabler())
    }
}

// MARK: - UINavigationControllerのスワイプジェスチャーを有効化
struct SwipeBackGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SwipeBackHostingController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class SwipeBackHostingController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // NavigationControllerのinteractivePopGestureRecognizerを有効化
        if let navigationController = self.navigationController {
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
            navigationController.interactivePopGestureRecognizer?.delegate = nil
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}
