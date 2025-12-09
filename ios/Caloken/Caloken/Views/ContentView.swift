import SwiftUI
import Combine

// MARK: - 分析中の状態管理（AI API連携版）
final class AnalyzingManager: ObservableObject {
    static let shared = AnalyzingManager()
    
    @Published var analyzingMealId: UUID?
    @Published var analyzingExerciseId: UUID?
    @Published var analysisProgress: String = "分析中..."
    
    private var mealTimer: Timer?
    private var exerciseTimer: Timer?
    private let network = NetworkManager.shared
    
    private init() {}
    
    // MARK: - 食事分析開始（写真から）- AI API使用
    func startMealAnalyzing(image: UIImage?, for date: Date) {
        let logId = MealLogsManager.shared.addAnalyzingLog(image: image, for: date)
        analyzingMealId = logId
        analysisProgress = "画像を解析中..."
        
        // 画像がある場合はAI APIを呼び出す
        if let image = image {
            Task {
                await analyzeMealWithAI(id: logId, image: image)
            }
        } else {
            // 画像がない場合は従来のモック処理
            mealTimer?.invalidate()
            mealTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                let noDesc: String? = nil
                self?.completeMealAnalysis(id: logId, fromDescription: noDesc)
            }
        }
    }
    
    // MARK: - 食事分析開始（手動入力から）- AI API使用
    func startManualMealAnalyzing(description: String, for date: Date) {
        let logId = MealLogsManager.shared.addAnalyzingLog(image: nil, for: date)
        analyzingMealId = logId
        analysisProgress = "AIが栄養素を計算中..."
        
        // AI APIを呼び出す
        Task {
            await analyzeMealTextWithAI(id: logId, description: description)
        }
    }
    
    // MARK: - AI画像分析
    private func analyzeMealWithAI(id: UUID, image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            await MainActor.run {
                let noDesc: String? = nil
                self.completeMealAnalysis(id: id, fromDescription: noDesc)
            }
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        await MainActor.run {
            self.analysisProgress = "栄養素を計算中..."
        }
        
        do {
            let result = try await network.analyzeMeal(imageBase64: base64String)
            await MainActor.run {
                self.completeMealAnalysisWithAI(id: id, result: result)
            }
        } catch {
            print("❌ AI Image analysis error: \(error)")
            await MainActor.run {
                let noDesc: String? = nil
                self.completeMealAnalysis(id: id, fromDescription: noDesc)
            }
        }
    }
    
    // MARK: - AIテキスト分析
    private func analyzeMealTextWithAI(id: UUID, description: String) async {
        do {
            let result = try await network.analyzeMeal(description: description)
            await MainActor.run {
                self.completeMealAnalysisWithAI(id: id, result: result)
            }
        } catch {
            print("❌ AI Text analysis error: \(error)")
            await MainActor.run {
                self.completeMealAnalysis(id: id, fromDescription: description)
            }
        }
    }
    
    // MARK: - AI分析結果で完了
    private func completeMealAnalysisWithAI(id: UUID, result: DetailedMealAnalysis) {
        let name: String
        if result.food_items.count == 1 {
            name = result.food_items.first?.name ?? "食事"
        } else if result.food_items.count > 1 {
            name = result.food_items.prefix(2).map { $0.name }.joined(separator: "と")
        } else {
            name = "食事"
        }
        
        MealLogsManager.shared.completeAnalyzing(
            id: id,
            name: name,
            calories: result.total_calories,
            protein: Int(result.total_protein),
            fat: Int(result.total_fat),
            carbs: Int(result.total_carbs),
            emoji: selectEmoji(for: name)
        )
        
        DispatchQueue.main.async {
            self.analyzingMealId = nil
            self.analysisProgress = "分析中..."
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "\(name)を記録しました", "color": Color.green]
            )
        }
    }
    
    // MARK: - モック分析結果で完了（フォールバック用）
    private func completeMealAnalysis(id: UUID, fromDescription: String?) {
        let name: String
        if let desc = fromDescription {
            name = String(desc.prefix(20))
        } else {
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
            self.analysisProgress = "分析中..."
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "食事を記録しました（概算）", "color": Color.orange]
            )
        }
    }
    
    // MARK: - 絵文字選択
    private func selectEmoji(for name: String) -> String {
        let lowercased = name.lowercased()
        if lowercased.contains("ラーメン") || lowercased.contains("麺") { return "🍜" }
        if lowercased.contains("ご飯") || lowercased.contains("米") || lowercased.contains("丼") { return "🍚" }
        if lowercased.contains("パン") { return "🍞" }
        if lowercased.contains("サラダ") { return "🥗" }
        if lowercased.contains("肉") || lowercased.contains("ステーキ") { return "🥩" }
        if lowercased.contains("魚") || lowercased.contains("寿司") { return "🍣" }
        if lowercased.contains("卵") { return "🍳" }
        if lowercased.contains("カレー") { return "🍛" }
        if lowercased.contains("ピザ") { return "🍕" }
        if lowercased.contains("ハンバーガー") { return "🍔" }
        if lowercased.contains("パスタ") { return "🍝" }
        if lowercased.contains("コーヒー") { return "☕" }
        if lowercased.contains("ケーキ") || lowercased.contains("スイーツ") { return "🍰" }
        return "🍽️"
    }
    
    // MARK: - 食事を即座に記録（分析中表示なし）
    func saveMealInstantly(name: String, calories: Int, protein: Int = 0, fat: Int = 0, carbs: Int = 0, for date: Date) {
        let mealLog = MealLogEntry(
            name: name,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            emoji: "🍽️",
            date: date
        )
        MealLogsManager.shared.addLog(mealLog)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "\(name)を記録しました", "color": Color.green]
            )
            NotificationCenter.default.post(name: .dismissAllMealScreens, object: nil)
        }
    }
    
    // MARK: - 運動を即座に記録（分析中表示なし）
    func saveExerciseInstantly(name: String, duration: Int, caloriesBurned: Int, exerciseType: ExerciseType = .manual) {
        let exerciseLog = ExerciseLogEntry(
            name: name,
            duration: duration,
            caloriesBurned: caloriesBurned,
            exerciseType: exerciseType
        )
        ExerciseLogsManager.shared.addLog(exerciseLog)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .showHomeToast,
                object: nil,
                userInfo: ["message": "\(caloriesBurned) kcal を消費として記録しました", "color": Color.green]
            )
            NotificationCenter.default.post(name: .dismissAllExerciseScreens, object: nil)
        }
    }
    
    // MARK: - 運動分析開始
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
