import Foundation
import StoreKit
import Combine

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isSubscribed: Bool = false
    @Published var isChecking: Bool = false
    
    // サブスクリプションのProduct ID
    private let subscriptionProductIds = [
        "com.caloken.subscription.monthly",
        "com.caloken.subscription.yearly"
    ]
    
    private var updateListenerTask: Task<Void, Error>?
    
    nonisolated init() {
        // 起動時にトランザクション更新を監視開始とチェックを行う
        Task { @MainActor in
            self.startTransactionListener()
            await self.checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - トランザクション監視
    private func startTransactionListener() {
        updateListenerTask = Task {
            for await result in Transaction.updates {
                await self.handleTransactionUpdate(result)
            }
        }
    }
    
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            // 有効なトランザクションがあれば課金済みとする
            if subscriptionProductIds.contains(transaction.productID) {
                if transaction.revocationDate == nil {
                    isSubscribed = true
                    print("✅ Subscription active: \(transaction.productID)")
                } else {
                    // 取り消された場合
                    await checkSubscriptionStatus()
                }
            }
            await transaction.finish()
        case .unverified(_, _):
            print("⚠️ Unverified transaction")
        }
    }
    
    // MARK: - サブスクリプション状態チェック
    func checkSubscriptionStatus() async {
        isChecking = true
        print("🔍 Checking subscription status...")
        
        var hasActiveSubscription = false
        
        // 現在有効なエンタイトルメントをチェック
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if subscriptionProductIds.contains(transaction.productID) {
                    // 有効期限をチェック
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            hasActiveSubscription = true
                            print("✅ Active subscription found: \(transaction.productID)")
                            print("   Expires: \(expirationDate)")
                        } else {
                            print("⚠️ Subscription expired: \(transaction.productID)")
                        }
                    } else {
                        // 有効期限がない場合（永続購入など）
                        hasActiveSubscription = true
                        print("✅ Active entitlement found: \(transaction.productID)")
                    }
                }
            case .unverified(_, _):
                print("⚠️ Unverified entitlement")
            }
        }
        
        isSubscribed = hasActiveSubscription
        isChecking = false
        
        print("🔍 Subscription check complete: \(isSubscribed ? "SUBSCRIBED ✅" : "NOT SUBSCRIBED ❌")")
    }
    
    // MARK: - 購入処理
    func purchase(productId: String) async throws -> Bool {
        print("💳 Starting purchase for: \(productId)")
        
        let products = try await Product.products(for: [productId])
        
        guard let product = products.first else {
            print("❌ Product not found: \(productId)")
            throw SubscriptionError.productNotFound
        }
        
        print("💳 Purchasing: \(product.displayName) - \(product.displayPrice)")
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                print("✅ Purchase verified!")
                isSubscribed = true
                await transaction.finish()
                return true
            case .unverified(_, _):
                print("❌ Purchase unverified")
                throw SubscriptionError.verificationFailed
            }
        case .userCancelled:
            print("🚫 Purchase cancelled by user")
            return false
        case .pending:
            print("⏳ Purchase pending")
            return false
        @unknown default:
            print("❓ Unknown purchase result")
            return false
        }
    }
    
    // MARK: - 購入復元
    func restorePurchases() async throws -> Bool {
        print("🔄 Restoring purchases...")
        
        // App Storeと同期
        try await AppStore.sync()
        
        // 再チェック
        await checkSubscriptionStatus()
        
        return isSubscribed
    }
}

// MARK: - エラー定義
enum SubscriptionError: LocalizedError {
    case productNotFound
    case verificationFailed
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "商品が見つかりませんでした"
        case .verificationFailed:
            return "購入の検証に失敗しました"
        case .purchaseFailed:
            return "購入処理に失敗しました"
        }
    }
}
