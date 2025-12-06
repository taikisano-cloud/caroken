import SwiftUI

struct S51_ExerciseDetailView: View {
    let exercise: SavedExerciseItem
    var existingLogId: UUID? = nil
    var existingLogDate: Date? = nil
    var isFromSaved: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName: String = ""
    @State private var duration: Int = 30
    @State private var calories: Int = 300
    @State private var showDurationPicker: Bool = false
    @State private var showCaloriesPicker: Bool = false
    @State private var isBookmarked: Bool = false
    @State private var showBookmarkAlert: Bool = false
    @FocusState private var isNameFieldFocused: Bool
    
    var isEditMode: Bool { existingLogId != nil }
    var isNewRecording: Bool { !isEditMode && !isFromSaved }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green)
                        .frame(width: 24, height: 24)
                    
                    TextField("運動名", text: $exerciseName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .textFieldStyle(.plain)
                        .focused($isNameFieldFocused)
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(isNameFieldFocused ? .green : .secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Button {
                    showDurationPicker = true
                } label: {
                    VStack(spacing: 8) {
                        Text("運動時間")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(duration)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                            Text("分")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("タップして変更")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                
                Button {
                    showCaloriesPicker = true
                } label: {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "flame.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("消費カロリー")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(calories)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("kcal")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("タップして変更")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor.systemGray3))
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if isNewRecording {
                        Button(action: {
                            if !isBookmarked {
                                addToSavedExercises()
                            }
                        }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 22))
                                .foregroundColor(isBookmarked ? .green : .secondary)
                                .frame(width: 56, height: 56)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(28)
                        }
                    }
                    
                    Button { saveExercise() } label: {
                        Text(isEditMode ? "更新する" : isFromSaved ? "今日の運動として記録" : "記録する")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(30)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("完了") { isNameFieldFocused = false }
                }
            }
        }
        .sheet(isPresented: $showDurationPicker) {
            DurationPickerSheet(duration: $duration)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCaloriesPicker) {
            CaloriesPickerSheet(calories: $calories)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .alert("保存しました！", isPresented: $showBookmarkAlert) {
            Button("OK") {}
        } message: {
            Text("\(exerciseName)を保存済みに追加しました")
        }
        .onAppear {
            exerciseName = exercise.name
            duration = exercise.duration
            calories = exercise.caloriesBurned
            if isNewRecording {
                checkIfSaved()
            }
        }
        .onTapGesture {
            isNameFieldFocused = false
        }
        .enableSwipeBack()
    }
    
    private func checkIfSaved() {
        isBookmarked = SavedExercisesManager.shared.savedExercises.contains { $0.name == exerciseName }
    }
    
    private func addToSavedExercises() {
        let savedExercise = SavedExercise(
            name: exerciseName,
            duration: duration,
            caloriesBurned: calories,
            exerciseType: .description,
            intensity: ""
        )
        SavedExercisesManager.shared.addExercise(savedExercise)
        isBookmarked = true
        showBookmarkAlert = true
    }
    
    private func saveExercise() {
        let exerciseLog = ExerciseLogEntry(
            id: existingLogId ?? UUID(),
            name: exerciseName,
            duration: duration,
            caloriesBurned: calories,
            exerciseType: .description,
            date: existingLogDate ?? Date()
        )
        
        if isEditMode {
            ExerciseLogsManager.shared.updateLog(exerciseLog)
        } else {
            ExerciseLogsManager.shared.addLog(exerciseLog)
        }
        
        // ホーム画面でトースト表示
        let message = isEditMode ? "\(exerciseName)を更新しました" : "\(exerciseName)を記録しました"
        NotificationCenter.default.post(
            name: .showHomeToast,
            object: nil,
            userInfo: ["message": message, "color": Color.green]
        )
        
        // 即座にホームに戻る（通知だけでdismissは呼ばない）
        NotificationCenter.default.post(name: .dismissAllExerciseScreens, object: nil)
    }
}

// MARK: - 運動時間ピッカーシート
struct DurationPickerSheet: View {
    @Binding var duration: Int
    @Environment(\.dismiss) private var dismiss
    @State private var tempDuration: Int = 30
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("キャンセル") { dismiss() }
                    .foregroundColor(.secondary)
                Spacer()
                Text("運動時間")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("完了") {
                    duration = tempDuration
                    dismiss()
                }
                .foregroundColor(.green)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            Picker("運動時間", selection: $tempDuration) {
                ForEach(Array(stride(from: 5, through: 180, by: 5)), id: \.self) { min in
                    Text("\(min) 分").tag(min)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 180)
        }
        .onAppear { tempDuration = duration }
    }
}

// MARK: - 消費カロリーピッカーシート
struct CaloriesPickerSheet: View {
    @Binding var calories: Int
    @Environment(\.dismiss) private var dismiss
    @State private var tempCalories: Int = 300
    
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
