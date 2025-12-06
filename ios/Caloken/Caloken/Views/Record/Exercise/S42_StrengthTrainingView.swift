import SwiftUI

struct S42_StrengthTrainingView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedIntensity: AnaerobicIntensity = .medium
    @State private var selectedDuration: Int = 30
    @State private var durationText: String = "30"
    
    let durationPresets = [15, 30, 45, 60, 90]
    
    private var exerciseName: String {
        "無酸素運動（\(selectedIntensity.name)）"
    }
    
    private var calculatedCalories: Int {
        let baseCalories: Double
        switch selectedIntensity {
        case .light: baseCalories = 3.0
        case .medium: baseCalories = 5.0
        case .heavy: baseCalories = 8.0
        }
        return Int(baseCalories * Double(selectedDuration))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("どのくらいの負荷でしたか？", systemImage: "dumbbell.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            ForEach(AnaerobicIntensity.allCases, id: \.self) { intensity in
                                AnaerobicIntensityButton(
                                    intensity: intensity,
                                    isSelected: selectedIntensity == intensity
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedIntensity = intensity
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label("時間", systemImage: "clock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            ForEach(durationPresets, id: \.self) { duration in
                                AnaerobicDurationButton(
                                    duration: duration,
                                    isSelected: selectedDuration == duration
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedDuration = duration
                                        durationText = "\(duration)"
                                    }
                                }
                            }
                        }
                        
                        HStack {
                            TextField("", text: $durationText)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.leading)
                                .onChange(of: durationText) { oldValue, newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        durationText = filtered
                                    }
                                    if let value = Int(filtered), value > 0 {
                                        selectedDuration = value
                                    } else if filtered.isEmpty {
                                        selectedDuration = 0
                                    }
                                }
                            
                            Spacer()
                            
                            Text("分")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 20)
                }
            }
            
            VStack {
                Button(action: { saveStrengthTraining() }) {
                    Text("記録する")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("無酸素運動")
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
            
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("完了") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
        .enableSwipeBack()
    }
    
    private func saveStrengthTraining() {
        let exerciseLog = ExerciseLogEntry(
            name: exerciseName,
            duration: selectedDuration,
            caloriesBurned: calculatedCalories,
            exerciseType: .strength,
            intensity: selectedIntensity.name
        )
        ExerciseLogsManager.shared.addLog(exerciseLog)
        
        // ホーム画面でトースト表示
        NotificationCenter.default.post(
            name: .showHomeToast,
            object: nil,
            userInfo: ["message": "\(exerciseName) \(selectedDuration)分を記録しました", "color": Color.green]
        )
        
        // 即座にホームに戻る
        NotificationCenter.default.post(name: .dismissAllExerciseScreens, object: nil)
        dismiss()
    }
}

// MARK: - 負荷レベル
enum AnaerobicIntensity: CaseIterable {
    case light, medium, heavy
    
    var name: String {
        switch self {
        case .light: return "軽い"
        case .medium: return "普通"
        case .heavy: return "激しい"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "figure.flexibility"
        case .medium: return "dumbbell"
        case .heavy: return "dumbbell.fill"
        }
    }
    
    var description: String {
        switch self {
        case .light: return "自重・ストレッチ"
        case .medium: return "ダンベル・マシン"
        case .heavy: return "バーベル・HIIT"
        }
    }
    
    var color: Color {
        switch self {
        case .light: return .green
        case .medium: return .orange
        case .heavy: return .red
        }
    }
}

// MARK: - 負荷選択ボタン
struct AnaerobicIntensityButton: View {
    let intensity: AnaerobicIntensity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? intensity.color : Color(UIColor.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: intensity.icon)
                        .font(.system(size: 26))
                        .foregroundColor(isSelected ? .white : Color(UIColor.systemGray))
                }
                
                Text(intensity.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? intensity.color : .primary)
                
                Text(intensity.description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? intensity.color.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? intensity.color : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - 時間選択ボタン
struct AnaerobicDurationButton: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(duration)分")
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.red : Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color(UIColor.systemGray4), lineWidth: 1)
                )
        }
    }
}
