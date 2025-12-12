import SwiftUI
import Combine

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedTab: Int = 0
    @State private var showRecordMenu: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastColor: Color = .green
    
    @State private var navigateToCamera: Bool = false
    @State private var navigateToExerciseMenu: Bool = false
    @State private var navigateToManualRecord: Bool = false
    @State private var navigateToSavedMeals: Bool = false
    @State private var navigateToWeightRecord: Bool = false
    
    @State private var hasCheckedSubscription: Bool = false
    @State private var showPaywall: Bool = false
    
    private let tabBarHeight: CGFloat = 90
    
    var body: some View {
        Group {
            if !hasCheckedSubscription {
                // 課金状態チェック中
                loadingView
            } else if !subscriptionManager.isSubscribed {
                // 未課金 → Paywall表示
                NavigationStack {
                    S51_PaywallView()
                }
            } else {
                // 課金済み → メインコンテンツ表示
                mainNavigationView
            }
        }
        .task {
            // 起動時に課金状態をチェック
            await subscriptionManager.checkSubscriptionStatus()
            hasCheckedSubscription = true
        }
        // 課金状態の変化を監視
        .onChange(of: subscriptionManager.isSubscribed) { _, newValue in
            if !newValue && hasCheckedSubscription {
                // 課金が切れた場合
                debugPrint("⚠️ Subscription expired")
            }
        }
    }
    
    // MARK: - ローディングビュー
    private var loadingView: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("確認中...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - メインナビゲーション
    private var mainNavigationView: some View {
        NavigationStack {
            ZStack {
                // メインコンテンツ
                mainContent
                
                // タブバー
                tabBarView
                
                // メニューオーバーレイ
                if showRecordMenu {
                    S39_RecordMenuView(
                        isPresented: $showRecordMenu,
                        navigateToCamera: $navigateToCamera,
                        navigateToExerciseMenu: $navigateToExerciseMenu,
                        navigateToManualRecord: $navigateToManualRecord,
                        navigateToSavedMeals: $navigateToSavedMeals,
                        navigateToWeightRecord: $navigateToWeightRecord
                    )
                    .transition(.opacity)
                }
                
                // トーストオーバーレイ
                if showToast {
                    VStack {
                        ToastView(message: toastMessage, color: toastColor)
                            .padding(.top, 60)
                        Spacer()
                    }
                    .zIndex(100)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToCamera) {
                S45_CameraView()
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $navigateToExerciseMenu) {
                S40_ExerciseMenuView()
            }
            .navigationDestination(isPresented: $navigateToManualRecord) {
                S48_ManualRecordView()
            }
            .navigationDestination(isPresented: $navigateToSavedMeals) {
                S50_SavedMealView()
            }
            .navigationDestination(isPresented: $navigateToWeightRecord) {
                S49_WeightRecordView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showHomeToast)) { notification in
            handleToastNotification(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllMealScreens)) { _ in
            navigateToCamera = false
            navigateToManualRecord = false
            navigateToSavedMeals = false
            showRecordMenu = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllExerciseScreens)) { _ in
            navigateToExerciseMenu = false
            showRecordMenu = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllWeightScreens)) { _ in
            navigateToWeightRecord = false
            showRecordMenu = false
        }
        .onChange(of: navigateToCamera) { _, newValue in if newValue { showRecordMenu = false } }
        .onChange(of: navigateToExerciseMenu) { _, newValue in if newValue { showRecordMenu = false } }
        .onChange(of: navigateToManualRecord) { _, newValue in if newValue { showRecordMenu = false } }
        .onChange(of: navigateToSavedMeals) { _, newValue in if newValue { showRecordMenu = false } }
        .onChange(of: navigateToWeightRecord) { _, newValue in if newValue { showRecordMenu = false } }
    }
    
    private var mainContent: some View {
        Group {
            if selectedTab == 0 {
                S24_HomeView(bottomPadding: tabBarHeight)
            } else {
                S38_ProgressView(bottomPadding: tabBarHeight)
            }
        }
        .animation(.none, value: selectedTab)
    }
    
    private var tabBarView: some View {
        VStack(spacing: 0) {
            Spacer()
            ModernTabBar(selectedTab: $selectedTab, showRecordMenu: $showRecordMenu)
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func handleToastNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let message = userInfo["message"] as? String {
            toastMessage = message
            toastColor = (userInfo["color"] as? Color) ?? .green
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showToast = false
            }
        }
    }
}

// MARK: - トーストビュー
struct ToastView: View {
    let message: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(color)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - モダンタブバー
struct ModernTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showRecordMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.3))
                .frame(height: 0.5)
            
            ZStack {
                Rectangle()
                    .fill(Color(UIColor.systemBackground))
                
                HStack(spacing: 0) {
                    TabButton(icon: "house.fill", title: "ホーム", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    Color.clear.frame(width: 90)
                    
                    TabButton(icon: "chart.bar.fill", title: "進捗", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                VStack {
                    Button { showRecordMenu = true } label: {
                        ZStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 64, height: 64)
                                .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(y: -20)
                    
                    Spacer()
                }
            }
            .frame(height: 56)
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - タブボタン
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .orange : Color(UIColor.systemGray))
            .frame(maxWidth: .infinity)
        }
    }
}
