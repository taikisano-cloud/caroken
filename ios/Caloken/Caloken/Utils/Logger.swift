import Foundation

// MARK: - Debug Logger
/// デバッグビルドでのみログを出力するユーティリティ
/// 本番ビルド（Release）ではログが出力されません

/// 通常のデバッグログ
func debugLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    debugPrint("[\(fileName):\(line)] \(message)")
    #endif
}

/// 絵文字付きデバッグログ（既存のprint文をそのまま置き換え可能）
func debugdebugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    debugPrint(output, terminator: terminator)
    #endif
}

// MARK: - カテゴリ別ログ

/// 認証関連のログ
func authLog(_ message: String) {
    #if DEBUG
    debugPrint("🔐 [Auth] \(message)")
    #endif
}

/// API通信のログ
func apiLog(_ message: String) {
    #if DEBUG
    debugPrint("📡 [API] \(message)")
    #endif
}

/// 購入関連のログ
func purchaseLog(_ message: String) {
    #if DEBUG
    debugPrint("💳 [Purchase] \(message)")
    #endif
}

/// エラーログ（本番でも記録したい場合はここを変更）
func errorLog(_ message: String, file: String = #file, line: Int = #line) {
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    debugPrint("❌ [Error][\(fileName):\(line)] \(message)")
    #endif
    // 本番でもエラーを記録したい場合は、ここにCrashlytics等を追加
    // Crashlytics.crashlytics().log(message)
}

/// 成功ログ
func successLog(_ message: String) {
    #if DEBUG
    debugPrint("✅ \(message)")
    #endif
}

/// 警告ログ
func warningLog(_ message: String) {
    #if DEBUG
    debugPrint("⚠️ [Warning] \(message)")
    #endif
}
