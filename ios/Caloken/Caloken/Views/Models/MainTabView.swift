import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showRecordMenu: Bool = false
    
    // ナビゲーション遷移用
    @State private var navigateToCamera: Bool = false
    @State private var navigateToExerciseMenu: Bool = false
    @State private var navigateToManualRecord: Bool = false
    @State private var navigateToSavedMeals: Bool = false
    @State private var navigateToWeightRecord: Bool = false
    
    // トースト通知用
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastColor: Color = .green
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $selectedTab) {
                    S24_HomeView()
                        .tag(0)
                    
                    S38_ProgressView()
                        .tag(1)
                }
                .overlay(alignment: .bottom) {
                    CustomTabBar(
                        selectedTab: $selectedTab,
                        showRecordMenu: $showRecordMenu
                    )
                }
                
                // +メニュー（半透明背景）
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
                
                // トースト通知
                if showToast {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(toastMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(toastColor)
                        .cornerRadius(30)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding(.top, 60)
                        
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .navigationBarHidden(true)
            // ナビゲーション遷移
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
        .ignoresSafeArea(.keyboard)
        // トースト通知を受信
        .onReceive(NotificationCenter.default.publisher(for: .showHomeToast)) { notification in
            if let userInfo = notification.userInfo,
               let message = userInfo["message"] as? String {
                toastMessage = message
                toastColor = (userInfo["color"] as? Color) ?? .green
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showToast = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showToast = false
                    }
                }
            }
        }
        // メニュー閉じる
        .onChange(of: navigateToCamera) { if $0 { showRecordMenu = false } }
        .onChange(of: navigateToExerciseMenu) { if $0 { showRecordMenu = false } }
        .onChange(of: navigateToManualRecord) { if $0 { showRecordMenu = false } }
        .onChange(of: navigateToSavedMeals) { if $0 { showRecordMenu = false } }
        .onChange(of: navigateToWeightRecord) { if $0 { showRecordMenu = false } }
        // 全画面を閉じる通知を受信
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllMealScreens)) { _ in
            showRecordMenu = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllExerciseScreens)) { _ in
            showRecordMenu = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllWeightScreens)) { _ in
            showRecordMenu = false
        }
    }
}

// MARK: - カスタムタブバー
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showRecordMenu: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // ホームタブ
            Button(action: { selectedTab = 0 }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .font(.system(size: 22))
                    Text("ホーム")
                        .font(.system(size: 10))
                }
                .foregroundColor(selectedTab == 0 ? .orange : .secondary)
                .frame(maxWidth: .infinity)
            }
            
            // 中央の+ボタン
            Button(action: { showRecordMenu = true }) {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 56, height: 56)
                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -16)
            
            // 進捗タブ
            Button(action: { selectedTab = 1 }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                        .font(.system(size: 22))
                    Text("進捗")
                        .font(.system(size: 10))
                }
                .foregroundColor(selectedTab == 1 ? .orange : .secondary)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}
