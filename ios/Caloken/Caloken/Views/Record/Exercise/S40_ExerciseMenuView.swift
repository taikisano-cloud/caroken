import SwiftUI

struct S40_ExerciseMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showRunning: Bool = false
    @State private var showStrength: Bool = false
    @State private var showOtherExercise: Bool = false
    @State private var showManualEntry: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Text("どんな運動をしましたか？")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    VStack(spacing: 12) {
                        // ランニング
                        ExerciseTypeCard(
                            icon: "figure.run",
                            title: "ランニング",
                            subtitle: "ウォーキング、ジョギング、スプリント",
                            color: .orange
                        ) {
                            showRunning = true
                        }
                        
                        // 無酸素運動
                        ExerciseTypeCard(
                            icon: "dumbbell.fill",
                            title: "無酸素運動",
                            subtitle: "筋トレ、ウェイト、HIIT",
                            color: .red
                        ) {
                            showStrength = true
                        }
                        
                        // その他の運動
                        ExerciseTypeCard(
                            icon: "figure.mixed.cardio",
                            title: "その他の運動",
                            subtitle: "ヨガ、水泳、サイクリングなど",
                            color: .green
                        ) {
                            showOtherExercise = true
                        }
                        
                        // マニュアル入力
                        ExerciseTypeCard(
                            icon: "flame.fill",
                            title: "消費カロリーを入力",
                            subtitle: "消費カロリーだけを直接入力",
                            color: .purple
                        ) {
                            showManualEntry = true
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("運動を記録")
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
        // ページ遷移（navigationDestination）
        .navigationDestination(isPresented: $showRunning) {
            S41_RunningView()
        }
        .navigationDestination(isPresented: $showStrength) {
            S42_StrengthTrainingView()
        }
        .navigationDestination(isPresented: $showOtherExercise) {
            S43_ExerciseManualEntryView()
        }
        .navigationDestination(isPresented: $showManualEntry) {
            S52_ExerciseManualEntryView()
        }
        // 運動記録完了時に全て閉じる
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllExerciseScreens)) { _ in
            showRunning = false
            showStrength = false
            showOtherExercise = false
            showManualEntry = false
            dismiss()
        }
        .enableSwipeBack()
    }
}

// MARK: - 運動タイプカード
struct ExerciseTypeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(UIColor.systemGray3))
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
