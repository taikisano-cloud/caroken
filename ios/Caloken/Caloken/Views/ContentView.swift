import SwiftUI
import Combine

// MARK: - 分析中の状態管理
final class AnalyzingManager: ObservableObject {
    static let shared = AnalyzingManager()
    
    @Published var analyzingMealId: UUID?
    @Published var analyzingExerciseId: UUID?
    
    private var mealTimer: Timer?
    private var exerciseTimer: Timer?
    
    private init() {}
    
    // 食事分析開始（写真から）
    func startMealAnalyzing(image: UIImage?, for date: Date) {
        let logId = MealLogsManager.shared.addAnalyzingLog(image: image, for: date)
        analyzingMealId = logId
        
        // 2秒後に分析完了
        mealTimer?.invalidate()
        mealTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.completeMealAnalysis(id: logId, fromDescription: nil)
        }
    }
    
    // 食事分析開始（手動入力から）
    func startManualMealAnalyzing(description: String, for date: Date) {
        let logId = MealLogsManager.shared.addAnalyzingLog(image: nil, for: date)
        analyzingMealId = logId
        
        // 2秒後に分析完了
        mealTimer?.invalidate()
        mealTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.completeMealAnalysis(id: logId, fromDescription: description)
        }
    }
    
    // 運動分析開始
    func startExerciseAnalyzing(description: String, duration: Int) {
        let logId = ExerciseLogsManager.shared.addAnalyzingLog(
            name: description,
            duration: duration,
            for: Date()
        )
        analyzingExerciseId = logId
        
        // 2秒後に分析完了
        exerciseTimer?.invalidate()
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.completeExerciseAnalysis(id: logId, description: description, duration: duration)
        }
    }
    
    private func completeMealAnalysis(id: UUID, fromDescription: String?) {
        // モック分析結果
        let name: String
        if let desc = fromDescription {
            // 手動入力からの場合は入力内容を使用
            name = String(desc.prefix(20))
        } else {
            // 写真からの場合はランダム
            let names = ["分析した料理", "美味しそうな料理", "ヘルシーな食事"]
            name = names.randomElement() ?? "食事"
        }
        let calories = Int.random(in: 300...600)
        let protein = Int.random(in: 15...35)
        let fat = Int.random(in: 10...25)
        let carbs = Int.random(in: 30...60)
        
        MealLogsManager.shared.completeAnalyzing(
            id: id,
            name: name,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            emoji: "🍽️"
        )
        
        DispatchQueue.main.async {
            self.analyzingMealId = nil
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "食事を記録しました", "color": Color.green]
            )
        }
    }
    
    private func completeExerciseAnalysis(id: UUID, description: String, duration: Int) {
        let estimatedCalories = Int(Double(duration) * 5.0)
        
        ExerciseLogsManager.shared.completeAnalyzing(
            id: id,
            caloriesBurned: estimatedCalories
        )
        
        DispatchQueue.main.async {
            self.analyzingExerciseId = nil
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "\(description)を記録しました", "color": Color.green]
            )
        }
    }
    
    func cancelMealAnalysis() {
        mealTimer?.invalidate()
        if let id = analyzingMealId {
            MealLogsManager.shared.removeLog(id: id)
        }
        analyzingMealId = nil
    }
    
    func cancelExerciseAnalysis() {
        exerciseTimer?.invalidate()
        if let id = analyzingExerciseId {
            ExerciseLogsManager.shared.removeLog(id: id)
        }
        analyzingExerciseId = nil
    }
}

// MARK: - ContentView
struct ContentView: View {
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
    
    private let tabBarHeight: CGFloat = 90
    
    var body: some View {
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
        .onChange(of: navigateToCamera) { if $0 { showRecordMenu = false } }
        .onChange(of: navigateToExerciseMenu) { if $0 { showRecordMenu = false } }
        .onChange(of: navigateToManualRecord) { if $0 { showRecordMenu = false } }
        .onChange(of: navigateToSavedMeals) { if $0 { showRecordMenu = false } }
        .onChange(of: navigateToWeightRecord) { if $0 { showRecordMenu = false } }
    }
    
    private var mainContent: some View {
        Group {
            if selectedTab == 0 {
                S24_HomeView(bottomPadding: tabBarHeight)
            } else {
                S38_ProgressView()
                    .padding(.bottom, tabBarHeight)
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
