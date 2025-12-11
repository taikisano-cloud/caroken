import SwiftUI

struct S24_HomeView: View {
    var bottomPadding: CGFloat = 0
    
    @State private var selectedDate = Date()
    @State private var showNutritionGoal = false
    @State private var showChat = false
    @ObservedObject private var logsManager = MealLogsManager.shared
    @ObservedObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Image("caloken_character")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .offset(x: 4)
                    
                    Text("カロ研")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color.titleColor)
                        .offset(x: -4, y: -3)
                    
                    Spacer()
                    
                    NavigationLink(destination: S27_1_SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                    }
                    .padding(.trailing, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                
                WeekCalendarView(selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
                
                MetricsTabView(selectedDate: $selectedDate, showNutritionGoal: $showNutritionGoal, showChat: $showChat)
                    .padding(.top, 4)
                
                RecentLogsCard(selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, bottomPadding)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showNutritionGoal) {
            S27_3_NutritionGoalView()
        }
        .navigationDestination(isPresented: $showChat) {
            CaloChatView(selectedDate: selectedDate, isPresented: $showChat)
        }
    }
}

// MARK: - ダークモード対応カラー
extension Color {
    static var dynamicAccent: Color {
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 1.0)
        })
    }
    
    static var titleColor: Color {
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0)
            : UIColor.black
        })
    }
}

// MARK: - 週カレンダー
struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentWeekOffset: Int = 0
    @ObservedObject private var logsManager = MealLogsManager.shared
    
    private let calendar = Calendar.current
    private let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
    
    private var currentMonthText: String {
        let midDate = getDate(for: 3, weekOffset: currentWeekOffset)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月"
        return formatter.string(from: midDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(currentMonthText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            
            TabView(selection: $currentWeekOffset) {
                ForEach(-52...52, id: \.self) { weekOffset in
                    weekView(offset: weekOffset).tag(weekOffset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 70)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func weekView(offset: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let date = getDate(for: index, weekOffset: offset)
                let day = calendar.component(.day, from: date)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)
                let hasLog = logsManager.hasLogs(for: date)
                
                VStack(spacing: 4) {
                    Text(weekdays[index])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        if isToday {
                            Circle()
                                .stroke(Color.dynamicAccent, style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                                .frame(width: 40, height: 40)
                        } else if hasLog {
                            Circle()
                                .fill(Color.dynamicAccent)
                                .frame(width: 40, height: 40)
                        } else {
                            Circle()
                                .stroke(Color(UIColor.systemGray3), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                                .frame(width: 40, height: 40)
                        }
                        
                        if isSelected && !isToday {
                            Circle()
                                .stroke(Color.dynamicAccent, lineWidth: 3)
                                .frame(width: 44, height: 44)
                        }
                        
                        Text("\(day)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(hasLog && !isToday ? Color(UIColor.white) : .primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture { selectedDate = date }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
    
    private func getDate(for weekdayIndex: Int, weekOffset: Int) -> Date {
        let today = Date()
        var cal = Calendar.current
        cal.firstWeekday = 2
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let startOfWeek = cal.date(from: components),
              let offsetWeek = cal.date(byAdding: .weekOfYear, value: weekOffset, to: startOfWeek) else {
            return today
        }
        return cal.date(byAdding: .day, value: weekdayIndex, to: offsetWeek) ?? today
    }
}

// MARK: - メトリクスタブビュー
struct MetricsTabView: View {
    @Binding var selectedDate: Date
    @Binding var showNutritionGoal: Bool
    @Binding var showChat: Bool
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 4) {
            TabView(selection: $currentPage) {
                CalorieWithAdviceCard(selectedDate: $selectedDate, showNutritionGoal: $showNutritionGoal, showChat: $showChat).tag(0)
                NutritionCard(selectedDate: $selectedDate, showNutritionGoal: $showNutritionGoal).tag(1)
                ActivityWaterCard(selectedDate: $selectedDate).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 340)
            
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? Color.dynamicAccent : Color(UIColor.systemGray3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - カロリー + アドバイスカード（時間帯・食事タイプ対応）
struct CalorieWithAdviceCard: View {
    @Binding var selectedDate: Date
    @Binding var showNutritionGoal: Bool
    @Binding var showChat: Bool
    @ObservedObject private var logsManager = MealLogsManager.shared
    @ObservedObject private var exerciseLogsManager = ExerciseLogsManager.shared
    @ObservedObject private var profileManager = UserProfileManager.shared
    
    @State private var adviceText: String = "今日も一緒にがんばろうにゃ！🐱"
    @State private var isLoadingAdvice: Bool = false
    @State private var lastMealCount: Int = 0
    
    var baseTarget: Int { profileManager.calorieGoal }
    var exerciseBonus: Int { exerciseLogsManager.totalCaloriesBurned(for: selectedDate) }
    var target: Int { baseTarget + exerciseBonus }
    var current: Int { logsManager.totalCalories(for: selectedDate) }
    var mealCount: Int { logsManager.logs(for: selectedDate).count }
    
    // 各食事タイプのカウント（時間帯から推測）
    var breakfastCount: Int {
        logsManager.logs(for: selectedDate).filter { log in
            let hour = Calendar.current.component(.hour, from: log.time)
            return hour >= 5 && hour < 10  // 5:00〜9:59 = 朝食
        }.count
    }
    var lunchCount: Int {
        logsManager.logs(for: selectedDate).filter { log in
            let hour = Calendar.current.component(.hour, from: log.time)
            return hour >= 10 && hour < 15  // 10:00〜14:59 = 昼食
        }.count
    }
    var dinnerCount: Int {
        logsManager.logs(for: selectedDate).filter { log in
            let hour = Calendar.current.component(.hour, from: log.time)
            return hour >= 17 && hour < 22  // 17:00〜21:59 = 夕食
        }.count
    }
    var snackCount: Int {
        logsManager.logs(for: selectedDate).filter { log in
            let hour = Calendar.current.component(.hour, from: log.time)
            // 朝食・昼食・夕食以外の時間帯 = 間食
            return (hour >= 15 && hour < 17) || (hour >= 22) || (hour < 5)
        }.count
    }
    
    var progressRatio: Double {
        guard target > 0 else { return 0 }
        return Double(current) / Double(target)
    }
    
    var isOverTarget: Bool { current > target }
    
    var body: some View {
        VStack(spacing: 8) {
            // カロリーカード
            Button { showNutritionGoal = true } label: {
                HStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .stroke(Color(UIColor.systemGray4), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        
                        if progressRatio >= 2.0 {
                            Circle()
                                .stroke(Color.red, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                        } else if progressRatio > 1.0 {
                            Circle()
                                .stroke(Color.dynamicAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                            Circle()
                                .trim(from: 0, to: progressRatio - 1.0)
                                .stroke(Color.red, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: progressRatio)
                        } else {
                            Circle()
                                .trim(from: 0, to: progressRatio)
                                .stroke(Color.dynamicAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: progressRatio)
                        }
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 32))
                            .foregroundColor(isOverTarget ? .red : .orange)
                    }
                    .padding(.leading, 16)
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("摂取カロリー")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(current)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                            Text("/\(target)")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        if exerciseBonus > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "figure.run")
                                    .font(.system(size: 11))
                                Text("+\(exerciseBonus)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // アドバイスカード
            Button { showChat = true } label: {
                HStack(alignment: .center, spacing: 0) {
                    Image("caloken_full")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 130)
                    
                    HStack(alignment: .center, spacing: 0) {
                        AdviceBubbleArrow()
                            .fill(Color(UIColor.tertiarySystemGroupedBackground))
                            .frame(width: 10, height: 20)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            if isLoadingAdvice {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("考え中...")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(adviceText)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(4)
                            }
                            
                            HStack {
                                Spacer()
                                Text("タップして相談 →")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                }
                .padding(.leading, 8)
                .padding(.trailing, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onAppear {
            lastMealCount = mealCount
            fetchAdvice()
        }
        .onChange(of: selectedDate) { _, _ in
            lastMealCount = mealCount
            fetchAdvice()
        }
        .onChange(of: mealCount) { oldCount, newCount in
            if newCount != lastMealCount {
                lastMealCount = newCount
                fetchAdvice()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mealLogAdded)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                fetchAdvice()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mealLogUpdated)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                fetchAdvice()
            }
        }
    }
    
    // MARK: - APIからアドバイスを取得（時間帯・食事タイプ対応）
    private func fetchAdvice() {
        isLoadingAdvice = true
        
        Task {
            do {
                let nutrients = logsManager.totalNutrients(for: selectedDate)
                let todayMeals = logsManager.logs(for: selectedDate).map { $0.name }.joined(separator: "、")
                
                // 時間帯と各食事タイプのカウントを送信
                let advice = try await NetworkManager.shared.fetchHomeAdvice(
                    todayCalories: current,
                    goalCalories: target,
                    todayProtein: nutrients.protein,
                    todayFat: nutrients.fat,
                    todayCarbs: nutrients.carbs,
                    todayMeals: todayMeals,
                    mealCount: mealCount,
                    breakfastCount: breakfastCount,
                    lunchCount: lunchCount,
                    dinnerCount: dinnerCount,
                    snackCount: snackCount
                )
                
                await MainActor.run {
                    adviceText = advice
                    isLoadingAdvice = false
                }
            } catch {
                await MainActor.run {
                    adviceText = generateLocalAdvice()
                    isLoadingAdvice = false
                }
            }
        }
    }
    
    // MARK: - ローカルフォールバック（時間帯対応）
    private func generateLocalAdvice() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let nutrients = logsManager.totalNutrients(for: selectedDate)
        
        // 朝（〜10時）
        if hour < 10 {
            if breakfastCount == 0 {
                return "おはようにゃ🌅 朝ごはんまだみたいだにゃ！軽くでもいいから食べてほしいにゃ🍳"
            } else {
                return "朝ごはん食べたんだにゃ！いいスタートだにゃ🐱✨"
            }
        }
        // 昼（10〜14時）
        else if hour < 14 {
            if lunchCount == 0 && breakfastCount == 0 {
                return "お昼だにゃ🌞 まだ何も食べてないみたい...お腹空いてない？🐱"
            } else if lunchCount == 0 {
                return "お昼の時間だにゃ🍱 ランチはどうするにゃ？"
            } else {
                return "ランチ完了だにゃ！午後もがんばろうにゃ💪"
            }
        }
        // 夕方（14〜18時）
        else if hour < 18 {
            if current == 0 {
                return "夕方になったにゃ...まだ何も食べてないみたい😿 大丈夫にゃ？"
            } else if nutrients.protein < 50 {
                return "たんぱく質がちょっと少ないかも🐱 夕食でお肉かお魚を食べるといいにゃ💪"
            } else {
                let remaining = target - current
                if remaining > 500 {
                    return "あと\(remaining)kcalくらい食べられるにゃ🍽️ 夕食が楽しみだにゃ！"
                } else {
                    return "いい感じに進んでるにゃ！夕食は軽めがおすすめだにゃ🐱"
                }
            }
        }
        // 夜（18時〜）
        else {
            if dinnerCount == 0 && current > 0 {
                return "夜だにゃ🌙 夕食はまだ？それとも今日は軽めにするにゃ？"
            } else if current > target {
                return "今日はちょっとオーバーしちゃったにゃ😅 明日は少し控えめにしようにゃ！"
            } else if dinnerCount > 0 {
                return "今日もお疲れ様だにゃ🌙 いい感じに食べられたにゃ✨"
            } else {
                return "今日も一日お疲れ様にゃ🐱 ゆっくり休んでにゃ💤"
            }
        }
    }
}

struct AdviceBubbleArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY - 8))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 8))
        path.closeSubpath()
        return path
    }
}

// MARK: - 栄養素カード（実際の値を表示）
struct NutritionCard: View {
    @Binding var selectedDate: Date
    @Binding var showNutritionGoal: Bool
    @ObservedObject private var logsManager = MealLogsManager.shared
    @ObservedObject private var profileManager = UserProfileManager.shared
    
    // 詳細栄養素を取得
    private var detailedNutrients: (protein: Int, fat: Int, carbs: Int, sugar: Int, fiber: Int, sodium: Int) {
        logsManager.detailedNutrients(for: selectedDate)
    }
    
    var body: some View {
        Button { showNutritionGoal = true } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    NutrientCardCompact(current: detailedNutrients.protein, target: profileManager.proteinGoal, color: Color.red.opacity(0.8), icon: "🥩", name: "たんぱく質")
                    NutrientCardCompact(current: detailedNutrients.fat, target: profileManager.fatGoal, color: Color.blue, icon: "🥑", name: "脂質")
                    NutrientCardCompact(current: detailedNutrients.carbs, target: profileManager.carbGoal, color: Color.orange.opacity(0.8), icon: "🍚", name: "炭水化物")
                }
                HStack(spacing: 6) {
                    NutrientCardCompact(current: detailedNutrients.sugar, target: profileManager.sugarGoal, color: .purple, icon: "🍬", name: "糖分")
                    NutrientCardCompact(current: detailedNutrients.fiber, target: profileManager.fiberGoal, color: Color.green, icon: "🌾", name: "食物繊維")
                    NutrientCardCompact(current: detailedNutrients.sodium, target: profileManager.sodiumGoal, color: Color(UIColor.systemGray), icon: "🧂", name: "ナトリウム", unit: "mg")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutrientCardCompact: View {
    let current: Int
    let target: Int
    let color: Color
    let icon: String
    let name: String
    var unit: String = "g"
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(current)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Text("/\(target)\(unit)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color(UIColor.systemGray5), lineWidth: 5)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                Text(icon)
                    .font(.system(size: 18))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 歩数・運動・水カード
struct ActivityWaterCard: View {
    @Binding var selectedDate: Date
    @State private var showWaterSettings = false
    @AppStorage("waterServingSize") private var waterUnit: Int = 250
    @ObservedObject private var exerciseLogsManager = ExerciseLogsManager.shared
    @ObservedObject private var waterLogsManager = WaterLogsManager.shared
    
    let steps: Int = 1989
    let stepsTarget: Int = 10000
    
    var waterAmount: Int {
        waterLogsManager.waterAmount(for: selectedDate)
    }
    
    var stepsCalories: Int {
        Int(Double(steps) * 0.04)
    }
    
    var runningCalories: Int {
        exerciseLogsManager.logs(for: selectedDate)
            .filter { $0.exerciseType == .running }
            .reduce(0) { $0 + $1.caloriesBurned }
    }
    
    var strengthCalories: Int {
        exerciseLogsManager.logs(for: selectedDate)
            .filter { $0.exerciseType == .strength }
            .reduce(0) { $0 + $1.caloriesBurned }
    }
    
    var otherCalories: Int {
        exerciseLogsManager.logs(for: selectedDate)
            .filter { $0.exerciseType != .running && $0.exerciseType != .strength }
            .reduce(0) { $0 + $1.caloriesBurned }
    }
    
    var totalCaloriesBurned: Int {
        stepsCalories + runningCalories + strengthCalories + otherCalories
    }
    
    var stepsProgress: Double { min(Double(steps) / Double(stepsTarget), 1.0) }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("歩数")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(steps.formatted())")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("/\(stepsTarget.formatted())")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color(UIColor.systemGray4), lineWidth: 8)
                                .frame(width: 70, height: 70)
                            Circle()
                                .trim(from: 0, to: stepsProgress)
                                .stroke(Color.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                            Image(systemName: "figure.walk")
                                .font(.system(size: 22))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color(UIColor.separator).opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("消費カロリー")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(totalCaloriesBurned)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("kcal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .frame(width: 14)
                            Text("歩数")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(stepsCalories) kcal")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .frame(width: 14)
                            Text("ランニング")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(runningCalories) kcal")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .frame(width: 14)
                            Text("無酸素運動")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(strengthCalories) kcal")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 160)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
            
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text("水分")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(waterAmount)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        Text("ml")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                Button { showWaterSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button {
                        waterLogsManager.removeWater(waterUnit, for: selectedDate)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(UIColor.label))
                            .frame(width: 34, height: 34)
                            .background(Color(UIColor.systemGray5))
                            .clipShape(Circle())
                    }
                    Button {
                        waterLogsManager.addWater(waterUnit, for: selectedDate)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(UIColor.systemBackground))
                            .frame(width: 34, height: 34)
                            .background(Color(UIColor.label))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .sheet(isPresented: $showWaterSettings) {
            WaterSettingsSheet(servingSize: $waterUnit)
        }
    }
}

// MARK: - 水設定シート
struct WaterSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var servingSize: Int
    @State private var selectedSize: Int = 250
    let sizes = [100, 150, 200, 250, 500, 750, 1000]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Text("1回の量")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text("\(selectedSize) ml")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Picker("量を選択", selection: $selectedSize) {
                    ForEach(sizes, id: \.self) { size in
                        Text("\(size)").tag(size)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Text("キャンセル")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                    Button {
                        servingSize = selectedSize
                        dismiss()
                    } label: {
                        Text("保存")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemBackground))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(UIColor.label))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("水分設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear { selectedSize = servingSize }
    }
}
