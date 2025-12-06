import SwiftUI

struct S27_3_NutritionGoalView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // 編集用シート表示フラグ
    @State private var showCaloriePicker: Bool = false
    @State private var showProteinPicker: Bool = false
    @State private var showCarbPicker: Bool = false
    @State private var showFatPicker: Bool = false
    @State private var showSugarPicker: Bool = false
    @State private var showFiberPicker: Bool = false
    @State private var showSodiumPicker: Bool = false
    
    // 詳細表示トグル
    @State private var showMoreNutrients: Bool = false
    
    // AI生成中フラグ
    @State private var isGenerating: Bool = false
    
    // PFCバランス計算
    private var proteinPercent: Int {
        let total = Double(profileManager.proteinGoal * 4 + profileManager.carbGoal * 4 + profileManager.fatGoal * 9)
        guard total > 0 else { return 0 }
        return Int((Double(profileManager.proteinGoal * 4) / total) * 100)
    }
    
    private var carbPercent: Int {
        let total = Double(profileManager.proteinGoal * 4 + profileManager.carbGoal * 4 + profileManager.fatGoal * 9)
        guard total > 0 else { return 0 }
        return Int((Double(profileManager.carbGoal * 4) / total) * 100)
    }
    
    private var fatPercent: Int {
        let total = Double(profileManager.proteinGoal * 4 + profileManager.carbGoal * 4 + profileManager.fatGoal * 9)
        guard total > 0 else { return 0 }
        return Int((Double(profileManager.fatGoal * 9) / total) * 100)
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // ヘッダーカード（コンパクト版）
                    CalorieHeaderCardCompact(calories: profileManager.calorieGoal) {
                        showCaloriePicker = true
                    }
                    .padding(.horizontal, 16)
                    
                    // メイン栄養素（PFC）
                    VStack(spacing: 8) {
                        Text("主要栄養素")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        
                        // たんぱく質
                        NutrientGoalRowCompact(
                            icon: "🥩",
                            iconBackground: .red,
                            title: "たんぱく質",
                            value: "\(profileManager.proteinGoal)g",
                            percentage: proteinPercent
                        ) {
                            showProteinPicker = true
                        }
                        
                        // 脂質
                        NutrientGoalRowCompact(
                            icon: "🥑",
                            iconBackground: .blue,
                            title: "脂質",
                            value: "\(profileManager.fatGoal)g",
                            percentage: fatPercent
                        ) {
                            showFatPicker = true
                        }
                        
                        // 炭水化物
                        NutrientGoalRowCompact(
                            icon: "🍚",
                            iconBackground: .orange,
                            title: "炭水化物",
                            value: "\(profileManager.carbGoal)g",
                            percentage: carbPercent
                        ) {
                            showCarbPicker = true
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // その他の栄養素（トグル展開）
                    VStack(spacing: 8) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showMoreNutrients.toggle()
                            }
                        } label: {
                            HStack {
                                Text("その他の栄養素")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Image(systemName: showMoreNutrients ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        if showMoreNutrients {
                            VStack(spacing: 8) {
                                // 糖分
                                NutrientGoalRowCompact(
                                    icon: "🍬",
                                    iconBackground: .purple,
                                    title: "糖分",
                                    value: "\(profileManager.sugarGoal)g",
                                    percentage: nil
                                ) {
                                    showSugarPicker = true
                                }
                                
                                // 食物繊維
                                NutrientGoalRowCompact(
                                    icon: "🌾",
                                    iconBackground: .green,
                                    title: "食物繊維",
                                    value: "\(profileManager.fiberGoal)g",
                                    percentage: nil
                                ) {
                                    showFiberPicker = true
                                }
                                
                                // ナトリウム
                                NutrientGoalRowCompact(
                                    icon: "🧂",
                                    iconBackground: Color(UIColor.systemGray),
                                    title: "ナトリウム",
                                    value: "\(profileManager.sodiumGoal)mg",
                                    percentage: nil
                                ) {
                                    showSodiumPicker = true
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }
            
            // 下部固定ボタン
            VStack {
                Spacer()
                
                Button {
                    startAutoGeneration()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("AIで目標を自動生成")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: Color.orange.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            
            // AI生成中オーバーレイ
            if isGenerating {
                AIGeneratingOverlay()
            }
        }
        .navigationTitle("目標")
        .navigationBarTitleDisplayMode(.large)
        // カロリーピッカー
        .sheet(isPresented: $showCaloriePicker) {
            CaloriePickerSheet(calories: Binding(
                get: { profileManager.calorieGoal },
                set: { newValue in
                    profileManager.calorieGoal = newValue
                    profileManager.saveNutritionGoals()
                }
            ))
            .presentationDetents([.height(300)])
        }
        // たんぱく質ピッカー
        .sheet(isPresented: $showProteinPicker) {
            NutrientPickerSheet(
                title: "たんぱく質目標",
                value: Binding(
                    get: { profileManager.proteinGoal },
                    set: { newValue in
                        profileManager.proteinGoal = newValue
                        profileManager.saveNutritionGoals()
                    }
                ),
                unit: "g",
                range: 0...400,
                step: 5
            )
            .presentationDetents([.height(300)])
        }
        // 炭水化物ピッカー
        .sheet(isPresented: $showCarbPicker) {
            NutrientPickerSheet(
                title: "炭水化物目標",
                value: Binding(
                    get: { profileManager.carbGoal },
                    set: { newValue in
                        profileManager.carbGoal = newValue
                        profileManager.saveNutritionGoals()
                    }
                ),
                unit: "g",
                range: 0...600,
                step: 5
            )
            .presentationDetents([.height(300)])
        }
        // 脂質ピッカー
        .sheet(isPresented: $showFatPicker) {
            NutrientPickerSheet(
                title: "脂質目標",
                value: Binding(
                    get: { profileManager.fatGoal },
                    set: { newValue in
                        profileManager.fatGoal = newValue
                        profileManager.saveNutritionGoals()
                    }
                ),
                unit: "g",
                range: 0...200,
                step: 5
            )
            .presentationDetents([.height(300)])
        }
        // 糖分ピッカー
        .sheet(isPresented: $showSugarPicker) {
            NutrientPickerSheet(
                title: "糖分目標",
                value: Binding(
                    get: { profileManager.sugarGoal },
                    set: { newValue in
                        profileManager.sugarGoal = newValue
                        profileManager.saveNutritionGoals()
                    }
                ),
                unit: "g",
                range: 0...100,
                step: 1
            )
            .presentationDetents([.height(300)])
        }
        // 食物繊維ピッカー
        .sheet(isPresented: $showFiberPicker) {
            NutrientPickerSheet(
                title: "食物繊維目標",
                value: Binding(
                    get: { profileManager.fiberGoal },
                    set: { newValue in
                        profileManager.fiberGoal = newValue
                        profileManager.saveNutritionGoals()
                    }
                ),
                unit: "g",
                range: 0...50,
                step: 1
            )
            .presentationDetents([.height(300)])
        }
        // ナトリウムピッカー
        .sheet(isPresented: $showSodiumPicker) {
            NutrientPickerSheet(
                title: "ナトリウム目標",
                value: Binding(
                    get: { profileManager.sodiumGoal },
                    set: { newValue in
                        profileManager.sodiumGoal = newValue
                        profileManager.saveNutritionGoals()
                    }
                ),
                unit: "mg",
                range: 0...5000,
                step: 100
            )
            .presentationDetents([.height(300)])
        }
    }
    
    private func startAutoGeneration() {
        isGenerating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                profileManager.calorieGoal = 2490
                profileManager.proteinGoal = 160
                profileManager.carbGoal = 307
                profileManager.fatGoal = 69
                profileManager.sugarGoal = 25
                profileManager.fiberGoal = 28
                profileManager.sodiumGoal = 2000
                profileManager.saveNutritionGoals()
                isGenerating = false
            }
        }
    }
}

// MARK: - AI生成中オーバーレイ
struct AIGeneratingOverlay: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var dots: String = ""
    @State private var progress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(rotation))
                    
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                        .scaleEffect(scale)
                }
                
                VStack(spacing: 8) {
                    Text("AIが目標を生成中\(dots)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("あなたの身体データを分析しています")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(UIColor.systemGray4))
                        .frame(width: 200, height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 200 * progress, height: 8)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemBackground))
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            scale = 1.15
        }
        
        withAnimation(.easeInOut(duration: 2.5)) {
            progress = 1.0
        }
        
        animateDots()
    }
    
    private func animateDots() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if dots.count >= 3 {
                dots = ""
            } else {
                dots += "."
            }
            animateDots()
        }
    }
}

// MARK: - カロリーヘッダーカード（コンパクト版・タップ可能）
struct CalorieHeaderCardCompact: View {
    let calories: Int
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("1日のカロリー目標")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(calories)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("kcal")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Text("🔥")
                        .font(.system(size: 28))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.systemGray3))
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: colorScheme == .light ? 1 : 0)
            )
        }
    }
}

// MARK: - 栄養素目標行（コンパクト版）
struct NutrientGoalRowCompact: View {
    let icon: String
    let iconBackground: Color
    let title: String
    let value: String
    let percentage: Int?
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconBackground.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Text(icon)
                        .font(.system(size: 18))
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(value)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let percent = percentage {
                        Text("\(percent)%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(8)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.systemGray3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(UIColor.separator), lineWidth: colorScheme == .light ? 1 : 0)
            )
        }
    }
}

// MARK: - カロリーピッカーシート
struct CaloriePickerSheet: View {
    @Binding var calories: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempCalories: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("キャンセル") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("カロリー目標")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("完了") {
                    calories = tempCalories
                    dismiss()
                }
                .foregroundColor(.orange)
                .fontWeight(.semibold)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            
            Picker("カロリー", selection: $tempCalories) {
                ForEach(Array(stride(from: 1000, through: 5000, by: 10)), id: \.self) { cal in
                    Text("\(cal) kcal").tag(cal)
                }
            }
            .pickerStyle(.wheel)
            .onAppear {
                tempCalories = calories
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - 栄養素ピッカーシート（汎用）
struct NutrientPickerSheet: View {
    let title: String
    @Binding var value: Int
    let unit: String
    let range: ClosedRange<Int>
    let step: Int
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempValue: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("キャンセル") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("完了") {
                    value = tempValue
                    dismiss()
                }
                .foregroundColor(.orange)
                .fontWeight(.semibold)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            
            Picker(title, selection: $tempValue) {
                ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { val in
                    Text("\(val) \(unit)").tag(val)
                }
            }
            .pickerStyle(.wheel)
            .onAppear {
                tempValue = value
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    NavigationStack {
        S27_3_NutritionGoalView()
    }
}
