import SwiftUI
import UserNotifications
import StoreKit
import HealthKit

// HealthKitを使用するかどうかのフラグ
private let useHealthKit = true

struct S2_OnboardingFlowView: View {
    @State private var currentStep: Int = 0
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = UserProfileManager.shared
    
    // ユーザー選択データ
    @State private var selectedGoal: Goal? = nil
    @State private var selectedExerciseFrequency: ExerciseFrequency? = nil
    @State private var selectedGender: Gender? = nil
    @State private var birthDate: Date = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
    @State private var currentWeight: Int = 70
    @State private var height: Int = 170
    @State private var targetWeight: Int = 65
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    
    // プラン作成状態
    @State private var planProgress: Double = 0
    @State private var planCreationPhase: PlanCreationPhase = .notStarted
    
    // 計算されたプラン（動的に計算）
    @State private var calculatedCalories: Int = 2000
    @State private var calculatedCarbs: Int = 250
    @State private var calculatedProtein: Int = 100
    @State private var calculatedFat: Int = 55
    @State private var calculatedSugar: Int = 25
    @State private var calculatedFiber: Int = 20
    @State private var calculatedSodium: Int = 2300
    
    // 遷移
    @State private var navigateToLogin: Bool = false
    @State private var isGoingForward: Bool = true
    @State private var isTransitioning: Bool = false
    
    private let totalSteps: Int = 10
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
    
    // MARK: - 年齢計算
    private var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 25
    }
    
    // MARK: - 栄養計算
    private func calculateNutritionPlan() {
        // 1. 基礎代謝量 (BMR) - Mifflin-St Jeor式
        let bmr: Double
        if selectedGender == .male {
            bmr = 10 * Double(currentWeight) + 6.25 * Double(height) - 5 * Double(age) + 5
        } else if selectedGender == .female {
            bmr = 10 * Double(currentWeight) + 6.25 * Double(height) - 5 * Double(age) - 161
        } else {
            // その他の場合は中間値
            let maleBmr = 10 * Double(currentWeight) + 6.25 * Double(height) - 5 * Double(age) + 5
            let femaleBmr = 10 * Double(currentWeight) + 6.25 * Double(height) - 5 * Double(age) - 161
            bmr = (maleBmr + femaleBmr) / 2
        }
        
        // 2. 活動係数
        let activityMultiplier: Double
        switch selectedExerciseFrequency {
        case .rarely:
            activityMultiplier = 1.2  // 座り仕事、ほぼ運動なし
        case .sometimes:
            activityMultiplier = 1.55 // 週3-5回の軽い運動
        case .often:
            activityMultiplier = 1.725 // 週6-7回の運動
        case .none:
            activityMultiplier = 1.4
        }
        
        // 3. TDEE (1日の総消費カロリー)
        let tdee = bmr * activityMultiplier
        
        // 4. 目標に応じたカロリー調整
        let targetCalories: Double
        let proteinRatio: Double
        let fatRatio: Double
        let carbRatio: Double
        
        switch selectedGoal {
        case .lose:
            // 減量: -20%（最低1200kcal）
            targetCalories = max(1200, tdee * 0.80)
            proteinRatio = 0.30  // 高たんぱく
            fatRatio = 0.25
            carbRatio = 0.45
        case .maintain:
            // 維持
            targetCalories = tdee
            proteinRatio = 0.25
            fatRatio = 0.25
            carbRatio = 0.50
        case .gain:
            // 増量: +15%
            targetCalories = tdee * 1.15
            proteinRatio = 0.25
            fatRatio = 0.20
            carbRatio = 0.55
        case .none:
            targetCalories = tdee
            proteinRatio = 0.25
            fatRatio = 0.25
            carbRatio = 0.50
        }
        
        // 5. PFCを計算
        // たんぱく質: 1g = 4kcal
        // 脂質: 1g = 9kcal
        // 炭水化物: 1g = 4kcal
        calculatedCalories = Int(targetCalories)
        calculatedProtein = Int((targetCalories * proteinRatio) / 4)
        calculatedFat = Int((targetCalories * fatRatio) / 9)
        calculatedCarbs = Int((targetCalories * carbRatio) / 4)
        
        // 6. その他の栄養素
        // 糖分: 総カロリーの5-10%（1g = 4kcal）
        calculatedSugar = Int((targetCalories * 0.05) / 4)
        
        // 食物繊維: 1000kcalあたり14g
        calculatedFiber = Int((targetCalories / 1000) * 14)
        
        // ナトリウム: 目標により調整
        switch selectedGoal {
        case .lose:
            calculatedSodium = 2000  // 減量時は控えめ
        case .maintain:
            calculatedSodium = 2300
        case .gain:
            calculatedSodium = 2500
        case .none:
            calculatedSodium = 2300
        }
    }
    
    private func goToNextStep() {
        guard !isTransitioning else { return }
        isTransitioning = true
        isGoingForward = true
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isTransitioning = false
        }
    }
    
    private func goToPreviousStep() {
        guard !isTransitioning else { return }
        isTransitioning = true
        isGoingForward = false
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep -= 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isTransitioning = false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                ProgressBarView(progress: progress)
                
                if currentStep < totalSteps - 1 {
                    Text("あと\(totalSteps - currentStep - 1)ステップ")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            ZStack {
                switch currentStep {
                case 0:
                    GoalSelectionView(selectedGoal: $selectedGoal) { goToNextStep() }
                        .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                case 1:
                    ExerciseFrequencyView(selectedFrequency: $selectedExerciseFrequency) { goToNextStep() }
                        .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                case 2:
                    GenderSelectionView(selectedGender: $selectedGender) { goToNextStep() }
                        .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                case 3:
                    BirthDateView(birthDate: $birthDate)
                        .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                case 4:
                    BodyMeasurementsView(currentWeight: $currentWeight, height: $height, targetWeight: $targetWeight)
                        .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                case 5:
                    GoalSettingsView(targetWeight: $targetWeight, targetDate: $targetDate)
                        .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                case 6:
                    NotificationPermissionView()
                        .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                case 7:
                    HealthKitConnectionView()
                        .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                case 8:
                    PlanCreationAnimationView(progress: $planProgress, phase: $planCreationPhase)
                        .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                case 9:
                    PlanDetailView(
                        targetDate: targetDate,
                        targetWeight: targetWeight,
                        calories: calculatedCalories,
                        carbs: calculatedCarbs,
                        protein: calculatedProtein,
                        fat: calculatedFat,
                        fiber: calculatedFiber,
                        sugar: calculatedSugar,
                        sodium: calculatedSodium
                    )
                    .transition(.asymmetric(insertion: .move(edge: isGoingForward ? .trailing : .leading), removal: .move(edge: isGoingForward ? .leading : .trailing)))
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .animation(.easeInOut(duration: 0.4), value: currentStep)
            
            if shouldShowContinueButton {
                Button {
                    guard !isTransitioning else { return }
                    handleContinue()
                } label: {
                    HStack {
                        Text(continueButtonTitle)
                            .font(.system(size: 18, weight: .bold))
                        if currentStep == 6 || currentStep == 7 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: canContinue ? [Color.orange, Color.orange.opacity(0.8)] : [Color.gray, Color.gray.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                }
                .disabled(!canContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if currentStep < 8 {
                    Button {
                        if currentStep == 0 {
                            dismiss()
                        } else {
                            goToPreviousStep()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToLogin) {
            S23_LoginView()
        }
    }
    
    private var continueButtonTitle: String {
        switch currentStep {
        case 9: return "始める！"
        default: return "続ける"
        }
    }
    
    private var shouldShowContinueButton: Bool {
        if [0, 1, 2].contains(currentStep) { return false }
        if currentStep == 8 && planCreationPhase != .completed { return false }
        return true
    }
    
    private var canContinue: Bool {
        switch currentStep {
        case 0: return selectedGoal != nil
        case 1: return selectedExerciseFrequency != nil
        case 2: return selectedGender != nil
        case 3...7: return true
        case 8: return planCreationPhase == .completed
        case 9: return true
        default: return true
        }
    }
    
    private func handleContinue() {
        switch currentStep {
        case 6: requestNotificationAuthorization()
        case 7: requestHealthKitAuthorization()
        case 9:
            saveOnboardingData()
            navigateToLogin = true
        default: goToNextStep()
        }
    }
    
    private func saveOnboardingData() {
        profileManager.setOnboardingData(
            goal: selectedGoal?.rawValue ?? "減量",
            exerciseFrequency: selectedExerciseFrequency?.rawValue ?? "たまに",
            gender: selectedGender?.rawValue ?? "Male",
            birthDate: birthDate,
            currentWeight: currentWeight,
            height: height,
            targetWeight: targetWeight,
            targetDate: targetDate,
            calories: calculatedCalories,
            carbs: calculatedCarbs,
            protein: calculatedProtein,
            fat: calculatedFat
        )
        
        // 追加の栄養素も保存
        profileManager.sugarGoal = calculatedSugar
        profileManager.fiberGoal = calculatedFiber
        profileManager.sodiumGoal = calculatedSodium
        profileManager.saveNutritionGoals()
        
        profileManager.completeOnboarding()
    }
    
    private func requestNotificationAuthorization() {
        isTransitioning = true
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                        DispatchQueue.main.async { self.proceedToNextStep() }
                    }
                default:
                    self.proceedToNextStep()
                }
            }
        }
    }
    
    private func proceedToNextStep() {
        self.isGoingForward = true
        withAnimation(.easeInOut(duration: 0.4)) { self.currentStep += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.isTransitioning = false }
    }
    
    private func requestHealthKitAuthorization() {
        isTransitioning = true
        guard useHealthKit, HKHealthStore.isHealthDataAvailable() else {
            proceedToNextStepAndStartPlan()
            return
        }
        let healthStore = HKHealthStore()
        var typesToRead: Set<HKObjectType> = []
        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) { typesToRead.insert(stepCount) }
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) { typesToRead.insert(bodyMass) }
        var typesToShare: Set<HKSampleType> = []
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) { typesToShare.insert(bodyMass) }
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { _, _ in
            DispatchQueue.main.async { self.proceedToNextStepAndStartPlan() }
        }
    }
    
    private func proceedToNextStepAndStartPlan() {
        self.isGoingForward = true
        withAnimation(.easeInOut(duration: 0.4)) { self.currentStep += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isTransitioning = false
            self.startPlanCreation()
        }
    }
    
    private func startPlanCreation() {
        // ✅ 栄養計算を実行
        calculateNutritionPlan()
        
        planCreationPhase = .calories
        let phases: [PlanCreationPhase] = [.calories, .carbs, .protein, .fat, .healthScore]
        for (index, phase) in phases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index + 1) * 0.4) {
                withAnimation {
                    self.planCreationPhase = phase
                    self.planProgress = Double(index + 1) / Double(phases.count)
                }
                if phase == .healthScore {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation {
                            self.planCreationPhase = .completed
                            self.currentStep += 1
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Enums
enum PlanCreationPhase: Int, Comparable {
    case notStarted = 0, calories = 1, carbs = 2, protein = 3, fat = 4, healthScore = 5, completed = 6
    static func < (lhs: PlanCreationPhase, rhs: PlanCreationPhase) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum Goal: String, CaseIterable {
    case lose = "減量", maintain = "維持", gain = "増量"
    var icon: String {
        switch self {
        case .lose: return "arrow.down.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .gain: return "arrow.up.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .lose: return .blue
        case .maintain: return .green
        case .gain: return .orange
        }
    }
}

enum Gender: String, CaseIterable {
    case male = "Male", female = "Female", other = "Other"
    var displayName: String {
        switch self {
        case .male: return "男性"
        case .female: return "女性"
        case .other: return "その他"
        }
    }
    var icon: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .other: return "person.fill"
        }
    }
    var color: Color {
        switch self {
        case .male: return .blue
        case .female: return .pink
        case .other: return .purple
        }
    }
}

enum ExerciseFrequency: String, CaseIterable {
    case rarely = "めったにしない", sometimes = "たまに", often = "よくする"
    var description: String {
        switch self {
        case .rarely: return "週0〜2回"
        case .sometimes: return "週3〜5回"
        case .often: return "週6回以上"
        }
    }
    var icon: String {
        switch self {
        case .rarely: return "figure.stand"
        case .sometimes: return "figure.walk"
        case .often: return "figure.run"
        }
    }
}

// MARK: - Views
struct ProgressBarView: View {
    let progress: Double
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(height: 8)
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [Color.orange, Color.orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}

struct GoalSelectionView: View {
    @Binding var selectedGoal: Goal?
    var onSelect: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Text("あなたの目的は？").font(.system(size: 28, weight: .bold)).padding(.top, 40)
            Text("目標に合わせてプランを作成します").font(.system(size: 16)).foregroundColor(.gray)
            Spacer()
            VStack(spacing: 16) {
                ForEach(Goal.allCases, id: \.self) { goal in
                    SelectionCard(title: goal.rawValue, icon: goal.icon, color: goal.color, isSelected: selectedGoal == goal) {
                        selectedGoal = goal
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onSelect() }
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer(); Spacer()
        }
    }
}

struct ExerciseFrequencyView: View {
    @Binding var selectedFrequency: ExerciseFrequency?
    var onSelect: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Text("運動の頻度は？").font(.system(size: 28, weight: .bold)).padding(.top, 40)
            Text("あなたの活動レベルを教えてください").font(.system(size: 16)).foregroundColor(.gray)
            Spacer()
            VStack(spacing: 16) {
                ForEach(ExerciseFrequency.allCases, id: \.self) { frequency in
                    SelectionCard(title: frequency.rawValue, subtitle: frequency.description, icon: frequency.icon, color: .orange, isSelected: selectedFrequency == frequency) {
                        selectedFrequency = frequency
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onSelect() }
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer(); Spacer()
        }
    }
}

struct GenderSelectionView: View {
    @Binding var selectedGender: Gender?
    var onSelect: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Text("性別を教えてください").font(.system(size: 28, weight: .bold)).padding(.top, 40)
            Text("正確なカロリー計算に使用します").font(.system(size: 16)).foregroundColor(.gray)
            Spacer()
            VStack(spacing: 16) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    SelectionCard(title: gender.displayName, icon: gender.icon, color: gender.color, isSelected: selectedGender == gender) {
                        selectedGender = gender
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onSelect() }
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer(); Spacer()
        }
    }
}

struct BirthDateView: View {
    @Binding var birthDate: Date
    var body: some View {
        VStack(spacing: 24) {
            Text("生年月日を教えてください").font(.system(size: 28, weight: .bold)).padding(.top, 40)
            Text("年齢に基づいて目標を調整します").font(.system(size: 16)).foregroundColor(.gray)
            Spacer()
            VStack(spacing: 16) {
                Text(formatBirthDate()).font(.system(size: 32, weight: .bold)).foregroundColor(.orange)
                DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .padding(.horizontal, 24)
            Spacer(); Spacer()
        }
    }
    private func formatBirthDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: birthDate)
    }
}

struct BodyMeasurementsView: View {
    @Binding var currentWeight: Int
    @Binding var height: Int
    @Binding var targetWeight: Int
    var body: some View {
        VStack(spacing: 24) {
            Text("体重と身長を教えてください").font(.system(size: 28, weight: .bold)).padding(.top, 40)
            Text("正確なプランを作成するために必要です").font(.system(size: 16)).foregroundColor(.gray)
            Spacer()
            HStack(spacing: 24) {
                MeasurementPickerCard(label: "体重", value: currentWeight, unit: "kg", range: 30...200, selection: $currentWeight)
                    .onChange(of: currentWeight) { _, newValue in targetWeight = max(30, newValue - 5) }
                MeasurementPickerCard(label: "身長", value: height, unit: "cm", range: 100...220, selection: $height)
            }
            .padding(.horizontal, 24)
            Spacer(); Spacer()
        }
    }
}

struct GoalSettingsView: View {
    @Binding var targetWeight: Int
    @Binding var targetDate: Date
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDay: Int = Calendar.current.component(.day, from: Date())
    private let years: [Int] = Array(Calendar.current.component(.year, from: Date())...Calendar.current.component(.year, from: Date()) + 5)
    private let months: [Int] = Array(1...12)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("目標を設定しましょう").font(.system(size: 28, weight: .bold)).padding(.top, 40)
            Text("後から変更できます").font(.system(size: 16)).foregroundColor(.gray)
            Spacer().frame(height: 20)
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Text("目標体重").font(.system(size: 14, weight: .medium)).foregroundColor(.gray)
                    Text("\(targetWeight)").font(.system(size: 36, weight: .bold)).foregroundColor(.orange)
                    Text("kg").font(.system(size: 14)).foregroundColor(.gray)
                    Picker("目標体重", selection: $targetWeight) {
                        ForEach(30...150, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.wheel).frame(width: 100, height: 120).clipped()
                }
                .frame(width: 110)
                
                VStack(spacing: 4) {
                    Text("達成期限").font(.system(size: 14, weight: .medium)).foregroundColor(.gray)
                    Text(formatDateDisplay()).font(.system(size: 16, weight: .bold)).foregroundColor(.orange).frame(height: 44)
                    HStack(spacing: 0) {
                        Picker("年", selection: $selectedYear) {
                            ForEach(years, id: \.self) { Text(String($0)).tag($0) }
                        }.pickerStyle(.wheel).frame(width: 80, height: 120).clipped()
                        Picker("月", selection: $selectedMonth) {
                            ForEach(months, id: \.self) { Text("\($0)月").tag($0) }
                        }.pickerStyle(.wheel).frame(width: 70, height: 120).clipped()
                        Picker("日", selection: $selectedDay) {
                            ForEach(validDays(), id: \.self) { Text("\($0)日").tag($0) }
                        }.pickerStyle(.wheel).frame(width: 70, height: 120).clipped()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .onAppear {
            let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            selectedYear = Calendar.current.component(.year, from: futureDate)
            selectedMonth = Calendar.current.component(.month, from: futureDate)
            selectedDay = Calendar.current.component(.day, from: futureDate)
            updateTargetDate()
        }
        .onChange(of: selectedYear) { _, _ in updateTargetDate() }
        .onChange(of: selectedMonth) { _, _ in updateTargetDate() }
        .onChange(of: selectedDay) { _, _ in updateTargetDate() }
    }
    
    private func formatDateDisplay() -> String { "\(selectedYear)年\(selectedMonth)月\(selectedDay)日" }
    private func validDays() -> [Int] {
        let dateComponents = DateComponents(year: selectedYear, month: selectedMonth)
        if let date = Calendar.current.date(from: dateComponents), let range = Calendar.current.range(of: .day, in: .month, for: date) {
            return Array(range)
        }
        return Array(1...31)
    }
    private func updateTargetDate() {
        let maxDay = validDays().last ?? 31
        if selectedDay > maxDay { selectedDay = maxDay }
        var components = DateComponents()
        components.year = selectedYear; components.month = selectedMonth; components.day = selectedDay
        if let date = Calendar.current.date(from: components) { targetDate = date }
    }
}

struct MeasurementPickerCard: View {
    let label: String; let value: Int; let unit: String; let range: ClosedRange<Int>
    @Binding var selection: Int
    var body: some View {
        VStack(spacing: 8) {
            Text(label).font(.system(size: 16, weight: .medium)).foregroundColor(.gray)
            Text("\(value)").font(.system(size: 48, weight: .bold)).foregroundColor(.orange).frame(height: 56)
            Text(unit).font(.system(size: 16)).foregroundColor(.gray)
            Picker(label, selection: $selection) {
                ForEach(range, id: \.self) { Text("\($0)").tag($0) }
            }.pickerStyle(.wheel).frame(height: 120).clipped()
        }.frame(maxWidth: .infinity)
    }
}

struct NotificationPermissionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            Text("通知で目標を\n達成しましょう").font(.system(size: 32, weight: .bold)).multilineTextAlignment(.center)
            Spacer().frame(height: 20)
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill").font(.system(size: 24)).foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("カロ研").font(.system(size: 16, weight: .semibold))
                    Text("今日の食事を記録しましょう！🍽️").font(.system(size: 14)).foregroundColor(.gray)
                }
                Spacer()
                Text("今").font(.system(size: 12)).foregroundColor(.gray)
            }
            .padding(16).background(Color(UIColor.secondarySystemBackground)).cornerRadius(12).padding(.horizontal, 32)
            Text("食事の記録リマインダーや\n目標達成の通知をお届けします").font(.system(size: 16)).foregroundColor(.gray).multilineTextAlignment(.center).padding(.top, 16)
            Spacer()
        }
    }
}

struct HealthKitConnectionView: View {
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            
            // 通知が未許可の場合の警告
            if notificationStatus == .denied {
                NotificationWarningBanner()
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(Color(UIColor.secondarySystemBackground)).frame(width: 120, height: 120).shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                Image(systemName: "heart.fill").font(.system(size: 50)).foregroundColor(.red)
            }
            Text("HealthKitに接続").font(.system(size: 32, weight: .bold))
            Text("カロ研とHealthアプリの間で\n日々の活動を同期します").font(.system(size: 16)).foregroundColor(.gray).multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal, 32)
            VStack(spacing: 12) {
                HealthKitFeatureRow(icon: "figure.walk", text: "歩数")
                HealthKitFeatureRow(icon: "flame.fill", text: "消費カロリー")
                HealthKitFeatureRow(icon: "scalemass.fill", text: "体重")
            }.padding(.horizontal, 48).padding(.top, 16)
            Spacer()
        }
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
}

struct NotificationWarningBanner: View {
    var body: some View {
        Button {
            // 設定アプリを開く
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("通知が許可されていません")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("タップして設定を開く")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
    }
}

struct HealthKitFeatureRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(.orange).frame(width: 28)
            Text(text).font(.system(size: 16)).foregroundColor(.primary)
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundColor(.green)
        }.padding(.vertical, 8)
    }
}

struct PlanCreationAnimationView: View {
    @Binding var progress: Double
    @Binding var phase: PlanCreationPhase
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            HStack(spacing: 20) {
                Text("🥛").font(.system(size: 50))
                Text("📖").font(.system(size: 60))
                Text("🍅").font(.system(size: 50))
            }
            .padding(.bottom, 20)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 48, weight: .bold))
            
            Text("プランを準備しています")
                .font(.system(size: 24, weight: .bold))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [Color.orange, Color.orange.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 40)
            
            Text("栄養プランを作成中...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("あなたのプラン")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                PlanCheckItem(title: "カロリー", isComplete: phase >= .calories)
                PlanCheckItem(title: "炭水化物", isComplete: phase >= .carbs)
                PlanCheckItem(title: "たんぱく質", isComplete: phase >= .protein)
                PlanCheckItem(title: "脂質", isComplete: phase >= .fat)
                PlanCheckItem(title: "ヘルスコア", isComplete: phase >= .healthScore)
            }
            .padding(20)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct PlanCheckItem: View {
    let title: String
    let isComplete: Bool
    
    var body: some View {
        HStack {
            Text("・\(title)")
                .font(.system(size: 15))
                .foregroundColor(.primary)
            Spacer()
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(0.8)
            }
        }
    }
}

struct PlanDetailView: View {
    let targetDate: Date
    let targetWeight: Int
    let calories: Int
    let carbs: Int
    let protein: Int
    let fat: Int
    let fiber: Int
    let sugar: Int
    let sodium: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("🎉").font(.system(size: 60))
                    HStack(spacing: 8) { Image(systemName: "checkmark.circle.fill").foregroundColor(.orange); Text("完了！").font(.system(size: 18)).foregroundColor(.orange) }
                    Text("\(formatDateFull(targetDate))までに\n\(targetWeight) kgを達成").font(.system(size: 22, weight: .bold)).multilineTextAlignment(.center)
                }.padding(.top, 20)
                
                VStack(spacing: 12) {
                    Text("1日の目標カロリー").font(.system(size: 16)).foregroundColor(.gray)
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(calories)").font(.system(size: 56, weight: .bold)).foregroundColor(.orange)
                        Text("kcal").font(.system(size: 20, weight: .semibold)).foregroundColor(.orange).padding(.bottom, 10)
                    }
                    Text("このカロリーを守ることで目標を達成できます").font(.system(size: 14)).foregroundColor(.gray)
                }.padding(24).frame(maxWidth: .infinity).background(Color.orange.opacity(0.1)).cornerRadius(16).padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("あなたのプラン").font(.system(size: 20, weight: .bold))
                        Text("1日の栄養バランス目標").font(.system(size: 14)).foregroundColor(.gray)
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        OnboardingNutrientCard(emoji: "🍚", label: "炭水化物", value: "\(carbs)g", color: .orange)
                        OnboardingNutrientCard(emoji: "🥩", label: "たんぱく質", value: "\(protein)g", color: .red)
                        OnboardingNutrientCard(emoji: "🥑", label: "脂質", value: "\(fat)g", color: .green)
                        OnboardingNutrientCard(emoji: "🌾", label: "食物繊維", value: "\(fiber)g", color: .brown)
                        OnboardingNutrientCard(emoji: "🍬", label: "糖分", value: "\(sugar)g", color: .pink)
                        OnboardingNutrientCard(emoji: "🧂", label: "ナトリウム", value: "\(sodium)mg", color: .gray)
                    }
                }.padding(20).background(Color(UIColor.systemGray6)).cornerRadius(16).padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("目標達成の方法").font(.system(size: 20, weight: .bold))
                    MethodRow(emoji: "📝", text: "毎日の食事を記録しましょう")
                    MethodRow(emoji: "🔥", text: "1日\(calories)kcalを目標にしましょう")
                    MethodRow(emoji: "⚖️", text: "栄養バランスを意識しましょう")
                    MethodRow(emoji: "💪", text: "適度な運動を心がけましょう")
                }.padding(20).background(Color(UIColor.systemGray6)).cornerRadius(16).padding(.horizontal, 16).padding(.bottom, 100)
            }
        }
    }
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "ja_JP"); formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

struct OnboardingNutrientCard: View {
    let emoji: String; let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Text(emoji).font(.system(size: 28))
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.gray)
        }.frame(maxWidth: .infinity).padding(.vertical, 12).background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
    }
}

struct MethodRow: View {
    let emoji: String; let text: String
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: 28))
            Text(text).font(.system(size: 15)).foregroundColor(.primary)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
    }
}

struct SelectionCard: View {
    let title: String; var subtitle: String? = nil; let icon: String; let color: Color; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.system(size: 24)).foregroundColor(isSelected ? .white : color).frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 18, weight: .semibold)).foregroundColor(isSelected ? .white : .primary)
                    if let subtitle = subtitle { Text(subtitle).font(.system(size: 14)).foregroundColor(isSelected ? .white.opacity(0.8) : .gray) }
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").font(.system(size: 24)).foregroundColor(.white) }
            }.padding(20).background(isSelected ? color : Color(UIColor.systemGray6)).cornerRadius(16)
        }
    }
}

#Preview { NavigationStack { S2_OnboardingFlowView() } }
