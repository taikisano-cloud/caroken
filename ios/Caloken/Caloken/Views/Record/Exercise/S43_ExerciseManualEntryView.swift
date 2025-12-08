import SwiftUI

struct S43_ExerciseManualEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var exerciseDescription: String = ""
    @State private var selectedDuration: Int = 30
    @State private var showDurationPicker: Bool = false
    @FocusState private var isDescriptionFocused: Bool
    
    private let durationOptions = Array(stride(from: 5, through: 180, by: 5))
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 運動内容入力（競合アプリスタイル）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("どんな運動をしましたか？")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // 競合アプリスタイルのテキストフィールド
                        ZStack(alignment: .topLeading) {
                            if exerciseDescription.isEmpty {
                                Text("例：ヨガ、水泳、サイクリング、ダンスなど")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                            }
                            
                            TextField("", text: $exerciseDescription)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .focused($isDescriptionFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    isDescriptionFocused = false
                                }
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green, lineWidth: 1.5)
                        )
                    }
                    
                    // 運動時間
                    VStack(alignment: .leading, spacing: 8) {
                        Text("運動時間")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Button(action: { showDurationPicker = true }) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.green)
                                Text("\(selectedDuration)分")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                    
                    // ヒント
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))
                        
                        Text("運動の種類と時間を細かく入力するとより正確にカロリーを計算できます")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.12))
                    .cornerRadius(10)
                }
                .padding(20)
            }
            
            // ボタンエリア
            VStack(spacing: 0) {
                Button(action: { saveExercise() }) {
                    Text("記録する")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(exerciseDescription.isEmpty ? Color(UIColor.systemGray3) : Color.green)
                        .cornerRadius(25)
                }
                .disabled(exerciseDescription.isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("その他の運動")
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
        .sheet(isPresented: $showDurationPicker) {
            ExerciseDurationPickerSheet(
                selectedDuration: $selectedDuration,
                options: durationOptions
            )
            .presentationDetents([.height(300)])
        }
        .enableSwipeBack()
        // 自動フォーカスを削除
    }
    
    private func saveExercise() {
        // ホーム画面で分析開始（運動タイプ）
        AnalyzingManager.shared.startExerciseAnalyzing(
            description: exerciseDescription,
            duration: selectedDuration
        )
        
        NotificationCenter.default.post(name: .dismissAllExerciseScreens, object: nil)
    }
}

// MARK: - 運動時間ピッカーシート
struct ExerciseDurationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDuration: Int
    let options: [Int]
    
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
                    selectedDuration = tempDuration
                    dismiss()
                }
                .foregroundColor(.green)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            Picker("運動時間", selection: $tempDuration) {
                ForEach(options, id: \.self) { min in
                    Text("\(min) 分").tag(min)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
        }
        .onAppear {
            tempDuration = selectedDuration
        }
    }
}
