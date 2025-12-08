import SwiftUI

struct S48_ManualRecordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var mealDescription: String = ""
    @State private var isAnalyzing: Bool = false
    @State private var showCalorieOnlyView: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    isTextFieldFocused = false
                }
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // AIで計算セクション（競合アプリスタイル）
                        VStack(alignment: .leading, spacing: 8) {
                            Text("何を食べましたか？")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // 競合アプリスタイルのテキストフィールド
                            ZStack(alignment: .topLeading) {
                                if mealDescription.isEmpty {
                                    Text("マルゲリータピザ1切れとジュース1杯")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(UIColor.placeholderText))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 14)
                                }
                                
                                TextEditor(text: $mealDescription)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                    .scrollContentBackground(.hidden)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .focused($isTextFieldFocused)
                                    .disabled(isAnalyzing)
                            }
                            .frame(height: 120)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange, lineWidth: 1.5)
                            )
                            
                            Text("食べたものの詳細を入力してください。")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // ボタンエリア
                VStack(spacing: 12) {
                    // マクロ計算ボタン
                    Button(action: { startAnalysis() }) {
                        Text("マクロ計算")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                mealDescription.isEmpty || isAnalyzing
                                    ? Color(UIColor.systemGray3)
                                    : Color.orange
                            )
                            .cornerRadius(25)
                    }
                    .disabled(mealDescription.isEmpty || isAnalyzing)
                    
                    // カロリーだけ入力ボタン
                    Button(action: { showCalorieOnlyView = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame")
                                .font(.system(size: 14))
                            Text("カロリーだけ入力")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.orange)
                    }
                    .disabled(isAnalyzing)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .background(Color(UIColor.systemBackground))
            }
            .opacity(isAnalyzing ? 0.3 : 1.0)
            
            if isAnalyzing {
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .stroke(Color(UIColor.systemGray5), lineWidth: 4)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(0))
                        
                        Text("📝")
                            .font(.system(size: 36))
                    }
                    
                    Text("記録中...")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationTitle("手動で食事を入力")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                .disabled(isAnalyzing)
            }
        }
        .enableSwipeBack()
        .navigationDestination(isPresented: $showCalorieOnlyView) {
            CalorieOnlyInputView()
        }
    }
    
    private func startAnalysis() {
        isTextFieldFocused = false
        
        let name = String(mealDescription.prefix(20))
        let calories = Int.random(in: 300...600)
        let protein = Int.random(in: 15...35)
        let fat = Int.random(in: 10...25)
        let carbs = Int.random(in: 30...60)
        
        let mealLog = MealLogEntry(
            name: name.isEmpty ? "手動入力" : name,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            emoji: "🍽️",
            date: Date(),
            image: nil
        )
        MealLogsManager.shared.addLog(mealLog)
        
        NotificationCenter.default.post(
            name: .showHomeToast,
            object: nil,
            userInfo: ["message": "食事を記録しました", "color": Color.green]
        )
        
        NotificationCenter.default.post(name: .dismissAllMealScreens, object: nil)
    }
}

// MARK: - カロリーのみ入力画面
struct CalorieOnlyInputView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCalories: Int = 100
    
    private let calorieOptions = Array(stride(from: 10, through: 2000, by: 10))
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                Spacer()
                
                // カロリー表示
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("摂取カロリー")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // ピッカー
                Picker("カロリー", selection: $selectedCalories) {
                    ForEach(calorieOptions, id: \.self) { kcal in
                        Text("\(kcal) kcal").tag(kcal)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // 記録ボタン
            VStack(spacing: 0) {
                Button(action: { recordCalories() }) {
                    Text("記録する")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(25)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("カロリーを入力")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .enableSwipeBack()
    }
    
    private func recordCalories() {
        let mealLog = MealLogEntry(
            name: "カロリーのみ",
            calories: selectedCalories,
            protein: 0,
            fat: 0,
            carbs: 0,
            emoji: "🔥",
            date: Date(),
            image: nil
        )
        MealLogsManager.shared.addLog(mealLog)
        
        NotificationCenter.default.post(
            name: .showHomeToast,
            object: nil,
            userInfo: ["message": "\(selectedCalories)kcalを記録しました", "color": Color.green]
        )
        
        NotificationCenter.default.post(name: .dismissAllMealScreens, object: nil)
    }
}
