import SwiftUI

// MARK: - カロリー + アドバイスカード（AIアドバイス対応版）
struct CalorieWithAdviceCard: View {
    @Binding var selectedDate: Date
    @Binding var showNutritionGoal: Bool
    @Binding var showChat: Bool
    @ObservedObject private var logsManager = MealLogsManager.shared
    @ObservedObject private var exerciseLogsManager = ExerciseLogsManager.shared
    @ObservedObject private var profileManager = UserProfileManager.shared
    @ObservedObject private var adviceManager = HomeAdviceManager.shared
    
    var baseTarget: Int { profileManager.calorieGoal }
    
    // 全運動の消費カロリー
    var exerciseBonus: Int { exerciseLogsManager.totalCaloriesBurned(for: selectedDate) }
    
    var target: Int { baseTarget + exerciseBonus }
    var current: Int { logsManager.totalCalories(for: selectedDate) }
    
    var progressRatio: Double {
        guard target > 0 else { return 0 }
        return Double(current) / Double(target)
    }
    
    var isOverTarget: Bool { current > target }
    
    // AIアドバイスを使用（ローディング中は前のアドバイスを表示）
    var adviceText: String {
        adviceManager.currentAdvice
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // カロリーカード（円グラフ + 数字）
            Button { showNutritionGoal = true } label: {
                HStack(spacing: 0) {
                    // 左側：円グラフ
                    ZStack {
                        Circle()
                            .stroke(Color(UIColor.systemGray4), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        
                        if progressRatio >= 2.0 {
                            Circle()
                                .stroke(Color.red, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                        } else if progressRatio > 1.0 {
                            Circle()
                                .stroke(Color.dynamicAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                            Circle()
                                .trim(from: 0, to: progressRatio - 1.0)
                                .stroke(Color.red, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: progressRatio)
                        } else {
                            Circle()
                                .trim(from: 0, to: progressRatio)
                                .stroke(Color.dynamicAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: progressRatio)
                        }
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 32))
                            .foregroundColor(isOverTarget ? .red : .orange)
                    }
                    .padding(.leading, 16)
                    
                    // 右側：カロリー数字（中央揃え）
                    VStack(alignment: .center, spacing: 4) {
                        Text("摂取カロリー")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(current)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                            Text("/\(target)")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // 運動ボーナス（小さめ）
                        if exerciseBonus > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "figure.run")
                                    .font(.system(size: 11))
                                Text("+\(exerciseBonus)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // アドバイスカード（カロちゃん）
            Button { showChat = true } label: {
                HStack(alignment: .center, spacing: 0) {
                    Image("caloken_full")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 130)
                    
                    HStack(alignment: .center, spacing: 0) {
                        AdviceBubbleArrow()
                            .fill(Color(UIColor.tertiarySystemGroupedBackground))
                            .frame(width: 10, height: 20)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            // ローディング中の表示
                            if adviceManager.isLoadingAdvice {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(adviceText)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(4)
                                }
                            } else {
                                Text(adviceText)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(4)
                            }
                            
                            HStack {
                                Spacer()
                                Text("タップして相談 →")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                }
                .padding(.leading, 8)
                .padding(.trailing, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onAppear {
            // 画面表示時にアドバイスを更新
            adviceManager.refreshAdvice()
        }
    }
}

struct AdviceBubbleArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY - 8))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 8))
        path.closeSubpath()
        return path
    }
}
