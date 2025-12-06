import SwiftUI
import StoreKit

struct S51_PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // ログイン状態を@AppStorageで管理
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    @State private var showAllPlans: Bool = false
    @State private var selectedPlan: PaywallSubscriptionPlan = .yearly
    @State private var isLoading: Bool = false
    @State private var navigateToTerms: Bool = false
    @State private var navigateToPrivacy: Bool = false
    @State private var showPurchaseError: Bool = false
    
    var body: some View {
        ZStack {
            // 背景
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 80)
                    
                    // タイトル
                    Text("目標達成を加速させるために\nカロ研をアンロックしましょう。")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    // 特典
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                        Text("契約の縛りなし - いつでもキャンセル可能")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // プラン選択（常に表示）
                    VStack(spacing: 12) {
                        PaywallPlanOptionRow(
                            title: "年間プラン",
                            price: "¥6,000/年",
                            subtitle: "¥500/月相当",
                            isSelected: selectedPlan == .yearly,
                            isBestValue: true
                        ) {
                            selectedPlan = .yearly
                        }
                        
                        PaywallPlanOptionRow(
                            title: "月間プラン",
                            price: "¥900/月",
                            subtitle: nil,
                            isSelected: selectedPlan == .monthly,
                            isBestValue: false
                        ) {
                            selectedPlan = .monthly
                        }
                        
                        PaywallPlanOptionRow(
                            title: "週間プラン",
                            price: "¥300/週",
                            subtitle: nil,
                            isSelected: selectedPlan == .weekly,
                            isBestValue: false
                        ) {
                            selectedPlan = .weekly
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // 続けるボタン
                    Button {
                        purchase()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .black : .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(colorScheme == .dark ? Color.white : Color.black)
                                .cornerRadius(12)
                        } else {
                            Text("続ける")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(colorScheme == .dark ? Color.white : Color.black)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 24)
                    
                    // 価格表示
                    Text("\(selectedPlan.price)/\(selectedPlan.period)\(selectedPlan.monthlyEquivalent != nil ? "（\(selectedPlan.monthlyEquivalent!)）" : "")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                    
                    // フッターリンク
                    HStack(spacing: 32) {
                        Button {
                            navigateToPrivacy = true
                        } label: {
                            Text("プライバシー")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            restorePurchases()
                        } label: {
                            Text("購入を復元")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            navigateToTerms = true
                        } label: {
                            Text("利用規約")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 32)
                }
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
        // @AppStorage を更新 → CalokenApp.swift で ContentView に自動切り替え
        // NavigationStack遷移ではないので、戻るボタンでログイン画面に戻ることはない
        withAnimation {
            isLoggedIn = true
        }
    }
    
    private func purchase() {
        isLoading = true
        
        Task {
            do {
                let productIds = [selectedPlan.productId]
                let products = try await Product.products(for: productIds)
                
                if let product = products.first {
                    let result = try await product.purchase()
                    
                    await MainActor.run {
                        switch result {
                        case .success(let verification):
                            switch verification {
                            case .verified:
                                isLoading = false
                                completePurchase()
                            case .unverified:
                                isLoading = false
                                showPurchaseError = true
                            }
                        case .userCancelled:
                            isLoading = false
                        case .pending:
                            isLoading = false
                        @unknown default:
                            isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        print("⚠️ Product not found. This is normal during development.")
                        isLoading = false
                        completePurchase()
                    }
                }
            } catch {
                await MainActor.run {
                    print("Purchase error: \(error)")
                    isLoading = false
                    completePurchase()
                }
            }
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        
        Task {
            do {
                try await AppStore.sync()
                
                for await result in Transaction.currentEntitlements {
                    if case .verified = result {
                        await MainActor.run {
                            isLoading = false
                            completePurchase()
                        }
                        return
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                    completePurchase()
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
    case weekly
    
    var price: String {
        switch self {
        case .yearly: return "¥6,000"
        case .monthly: return "¥900"
        case .weekly: return "¥300"
        }
    }
    
    var period: String {
        switch self {
        case .yearly: return "年"
        case .monthly: return "月"
        case .weekly: return "週"
        }
    }
    
    var monthlyEquivalent: String? {
        switch self {
        case .yearly: return "¥500/月"
        case .monthly: return nil
        case .weekly: return nil
        }
    }
    
    var productId: String {
        switch self {
        case .yearly: return "com.caloken.subscription.yearly"
        case .monthly: return "com.caloken.subscription.monthly"
        case .weekly: return "com.caloken.subscription.weekly"
        }
    }
}

// MARK: - プランオプション行
struct PaywallPlanOptionRow: View {
    let title: String
    let price: String
    let subtitle: String?
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if isBestValue {
                            Text("おすすめ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(price)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .orange : Color(UIColor.systemGray3))
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color(UIColor.separator), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        S51_PaywallView()
    }
}
