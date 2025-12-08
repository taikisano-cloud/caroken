import SwiftUI

struct S52_ExerciseManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var caloriesBurned: Int = 100
    @State private var showCaloriesPicker: Bool = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // ヘッダー
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    
                    Text("マニュアル入力")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // カロリー入力カード
                Button {
                    showCaloriesPicker = true
                } label: {
                    VStack(spacing: 12) {
                        Text("消費カロリー")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(caloriesBurned)")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.orange)
                            Text("kcal")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("タップして変更")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                
                // 説明
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    
                    Text("運動の種類や時間がわからない場合は、消費カロリーだけを直接入力できます")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // ボタンエリア
                Button(action: { saveManualEntry() }) {
                    Text("記録する")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(caloriesBurned > 0 ? Color.orange : Color(UIColor.systemGray3))
                        .cornerRadius(14)
                }
                .disabled(caloriesBurned == 0)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("消費カロリーを入力")
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
        .sheet(isPresented: $showCaloriesPicker) {
            ManualCaloriesPickerSheet(calories: $caloriesBurned)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .enableSwipeBack()
        // 自動フォーカス（onAppear）を削除
    }
    
    private func saveManualEntry() {
        let exerciseLog = ExerciseLogEntry(
            name: "マニュアル入力",
            duration: 0,
            caloriesBurned: caloriesBurned,
            exerciseType: .manual
        )
        ExerciseLogsManager.shared.addLog(exerciseLog)
        
        // ホーム画面でトースト表示
        NotificationCenter.default.post(
            name: .showHomeToast,
            object: nil,
            userInfo: ["message": "\(caloriesBurned) kcal を消費として記録しました", "color": Color.green]
        )
        
        // 即座にホームに戻る（通知だけでdismissは呼ばない）
        NotificationCenter.default.post(name: .dismissAllExerciseScreens, object: nil)
    }
}

// MARK: - マニュアル用カロリーピッカーシート
struct ManualCaloriesPickerSheet: View {
    @Binding var calories: Int
    @Environment(\.dismiss) private var dismiss
    @State private var tempCalories: Int = 100
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("キャンセル") { dismiss() }
                    .foregroundColor(.secondary)
                Spacer()
                Text("消費カロリー")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("完了") {
                    calories = tempCalories
                    dismiss()
                }
                .foregroundColor(.orange)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            Picker("消費カロリー", selection: $tempCalories) {
                ForEach(Array(stride(from: 10, through: 2000, by: 10)), id: \.self) { cal in
                    Text("\(cal) kcal").tag(cal)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 180)
        }
        .onAppear { tempCalories = calories }
    }
}
