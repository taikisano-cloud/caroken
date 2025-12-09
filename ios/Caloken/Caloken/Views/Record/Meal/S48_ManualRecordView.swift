import SwiftUI

struct S48_ManualRecordView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var mealDescription: String = ""
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
                        // AIで計算セクション
                        VStack(alignment: .leading, spacing: 8) {
                            Text("何を食べましたか？")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // テキストフィールド
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
                            }
                            .frame(height: 120)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange, lineWidth: 1.5)
                            )
                            
                            Text("食べたものの詳細を入力してください。AIが栄養素を計算します。")
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
                    Button(action: { startAIAnalysis() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("AIでマクロ計算")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            mealDescription.isEmpty
                            ? Color(UIColor.systemGray3)
                            : Color.orange
                        )
                        .cornerRadius(25)
                    }
                    .disabled(mealDescription.isEmpty)
                    
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
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .background(Color(UIColor.systemBackground))
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
            }
        }
        .enableSwipeBack()
        .navigationDestination(isPresented: $showCalorieOnlyView) {
            CalorieOnlyInputView()
        }
    }
    
    // MARK: - AI分析開始
    private func startAIAnalysis() {
        isTextFieldFocused = false
        
        // AnalyzingManagerでAI分析を開始
        AnalyzingManager.shared.startManualMealAnalyzing(description: mealDescription, for: Date())
        
        // ホーム画面に戻る
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
