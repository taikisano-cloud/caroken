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
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("どんな運動をしましたか？")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("例：ヨガ、水泳、サイクリング、ダンスなど", text: $exerciseDescription)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .padding(16)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .focused($isDescriptionFocused)
                            .submitLabel(.send)
                            .onSubmit {
                                if !exerciseDescription.isEmpty {
                                    saveExercise()
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("運動時間")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Button(action: { showDurationPicker = true }) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.green)
                                Text("\(selectedDuration)分")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    
                    // ヒント
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                        
                        Text("運動の種類と時間を細かく入力するとより正確にカロリーを計算できます")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(12)
                }
                .padding(20)
            }
            
            // キーボード上のボタンエリア（角丸）
            VStack(spacing: 0) {
                Button(action: { saveExercise() }) {
                    Text("記録する")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(exerciseDescription.isEmpty ? Color(UIColor.systemGray3) : Color.green)
                        .cornerRadius(14)
                }
                .disabled(exerciseDescription.isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                RoundedCornerShape(corners: [.topLeft, .topRight], radius: 20)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .background(Color(UIColor.systemGroupedBackground))
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
        .onAppear {
            // 画面表示時にテキストフィールドにフォーカス
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isDescriptionFocused = true
            }
        }
        .enableSwipeBack()
    }
    
    private func saveExercise() {
        // ホーム画面で分析開始（運動タイプ）
        AnalyzingManager.shared.startExerciseAnalyzing(
            description: exerciseDescription,
            duration: selectedDuration
        )
        
        // 即座にホームに戻る（通知だけでdismissは呼ばない）
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

// MARK: - 上だけ角丸のShape
private struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
