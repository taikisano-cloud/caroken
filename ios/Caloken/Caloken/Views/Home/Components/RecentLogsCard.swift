import SwiftUI

// MARK: - 最近のログカード
struct RecentLogsCard: View {
    @Binding var selectedDate: Date
    @StateObject private var mealLogsManager = MealLogsManager.shared
    @StateObject private var exerciseLogsManager = ExerciseLogsManager.shared
    
    var mealLogs: [MealLogEntry] {
        mealLogsManager.logs(for: selectedDate)
    }
    
    var exerciseLogs: [ExerciseLogEntry] {
        exerciseLogsManager.logs(for: selectedDate)
    }
    
    var isEmpty: Bool {
        mealLogs.isEmpty && exerciseLogs.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近のログ")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                if !Calendar.current.isDateInToday(selectedDate) {
                    Text(formatDate(selectedDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            
            if isEmpty {
                VStack(spacing: 16) {
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 12) {
                        Text("+ ボタンから記録してみよう！")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 14)
                        
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.orange)
                            .rotationEffect(.degrees(45))
                    }
                    
                    Spacer().frame(height: 60)
                }
                .frame(maxWidth: .infinity)
            } else {
                // 食事ログ
                ForEach(mealLogs) { log in
                    CompactMealLogCard(log: log) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            mealLogsManager.removeLog(log)
                        }
                    }
                }
                
                // 運動ログ
                ForEach(exerciseLogs) { log in
                    CompactExerciseLogCard(log: log) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            exerciseLogsManager.removeLog(log)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - コンパクト食事ログカード
struct CompactMealLogCard: View {
    let log: MealLogEntry
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var showDetail = false
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 削除ボタン背景
            Color.red.cornerRadius(16)
            
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                    Text("削除")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(width: 80)
            }
            
            // メインカード
            HStack(spacing: 12) {
                // 左側：画像/アイコン（丸形）
                ZStack {
                    if log.isAnalyzing {
                        // 分析中：ぐるぐるスピナー
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(rotation))
                            .onAppear {
                                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    rotation = 360
                                }
                            }
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                    } else if let image = log.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 右側：情報
                VStack(alignment: .leading, spacing: 4) {
                    // 名前と時間
                    HStack {
                        Text(log.isAnalyzing ? "分析中..." : log.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(log.isAnalyzing ? .secondary : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(log.timeString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(8)
                    }
                    
                    if log.isAnalyzing {
                        // 分析中メッセージ
                        Text("AIがカロリーを計算しています...")
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                    } else {
                        // カロリー
                        HStack(spacing: 4) {
                            Text("\(log.calories)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            Text("kcal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // 栄養素（横並び）
                        HStack(spacing: 12) {
                            CompactNutrientBadge(icon: "🥩", value: log.protein, unit: "g", color: .red)
                            CompactNutrientBadge(icon: "🥑", value: log.fat, unit: "g", color: .blue)
                            CompactNutrientBadge(icon: "🍚", value: log.carbs, unit: "g", color: .orange)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .offset(x: offset)
            .onTapGesture {
                // 分析中はタップ無効
                guard !log.isAnalyzing else { return }
                
                if offset == 0 {
                    showDetail = true
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = 0
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        // 分析中はスワイプ無効
                        guard !log.isAnalyzing else { return }
                        
                        let translation = value.translation.width
                        let verticalMovement = abs(value.translation.height)
                        let horizontalMovement = abs(translation)
                        
                        if horizontalMovement > verticalMovement && horizontalMovement > 10 {
                            if translation < 0 {
                                offset = translation
                            } else if offset < 0 {
                                offset = min(0, offset + translation * 0.5)
                            }
                        }
                    }
                    .onEnded { value in
                        guard !log.isAnalyzing else { return }
                        
                        let velocity = value.predictedEndTranslation.width
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if velocity < -500 || offset < -150 {
                                offset = -UIScreen.main.bounds.width
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDelete()
                                }
                            } else if offset < -50 {
                                offset = -80
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showDetail) {
            S46_MealDetailView(
                result: MealAnalysisData(
                    foodItems: [MealFoodItem(name: log.name, amount: "1食分", calories: log.calories, protein: Double(log.protein), fat: Double(log.fat), carbs: Double(log.carbs), sugar: 0, fiber: 0, sodium: 0)],
                    totalCalories: log.calories,
                    totalProtein: Double(log.protein),
                    totalFat: Double(log.fat),
                    totalCarbs: Double(log.carbs),
                    totalSugar: 0,
                    totalFiber: 0,
                    totalSodium: 0,
                    mealImage: nil,
                    characterComment: "\(log.name)だね！\nおいしそう〜🍴"
                ),
                capturedImage: log.image,
                existingLogId: log.id,
                existingLogDate: log.date,
                isFromLog: true
            )
        }
    }
}

// MARK: - コンパクト運動ログカード
struct CompactExerciseLogCard: View {
    let log: ExerciseLogEntry
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var showDetail = false
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 削除ボタン背景
            Color.red.cornerRadius(16)
            
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                    Text("削除")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(width: 80)
            }
            
            // メインカード
            HStack(spacing: 12) {
                // 左側：アイコン（丸形）
                ZStack {
                    if log.isAnalyzing {
                        // 分析中：ぐるぐるスピナー
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(rotation))
                            .onAppear {
                                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    rotation = 360
                                }
                            }
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    } else {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: log.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                    }
                }
                
                // 右側：情報
                VStack(alignment: .leading, spacing: 4) {
                    // 名前と時間
                    HStack {
                        Text(log.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(log.timeString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(8)
                    }
                    
                    if log.isAnalyzing {
                        // 分析中メッセージ
                        Text("消費カロリーを計算しています...")
                            .font(.system(size: 13))
                            .foregroundColor(.green)
                    } else {
                        // カロリー
                        HStack(spacing: 4) {
                            Text("\(log.caloriesBurned)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            Text("kcal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // 詳細情報
                        if log.duration > 0 {
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Text("\(log.duration) 分")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .offset(x: offset)
            .onTapGesture {
                // 分析中はタップ無効
                guard !log.isAnalyzing else { return }
                
                if offset == 0 {
                    showDetail = true
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = 0
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        guard !log.isAnalyzing else { return }
                        
                        let translation = value.translation.width
                        let verticalMovement = abs(value.translation.height)
                        let horizontalMovement = abs(translation)
                        
                        if horizontalMovement > verticalMovement && horizontalMovement > 10 {
                            if translation < 0 {
                                offset = translation
                            } else if offset < 0 {
                                offset = min(0, offset + translation * 0.5)
                            }
                        }
                    }
                    .onEnded { value in
                        guard !log.isAnalyzing else { return }
                        
                        let velocity = value.predictedEndTranslation.width
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if velocity < -500 || offset < -150 {
                                offset = -UIScreen.main.bounds.width
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDelete()
                                }
                            } else if offset < -50 {
                                offset = -80
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showDetail) {
            S51_ExerciseDetailView(
                exercise: SavedExerciseItem(
                    name: log.name,
                    duration: log.duration,
                    caloriesBurned: log.caloriesBurned,
                    icon: log.icon
                ),
                existingLogId: log.id,
                existingLogDate: log.date
            )
        }
    }
}

// MARK: - コンパクト栄養素バッジ
struct CompactNutrientBadge: View {
    let icon: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 12))
            Text("\(value)\(unit)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)
        }
    }
}
