import SwiftUI

struct S39_RecordMenuView: View {
    @Binding var isPresented: Bool
    
    // ContentView/MainTabViewへの遷移フラグ
    @Binding var navigateToCamera: Bool
    @Binding var navigateToExerciseMenu: Bool
    @Binding var navigateToManualRecord: Bool
    @Binding var navigateToSavedMeals: Bool
    @Binding var navigateToWeightRecord: Bool
    
    var body: some View {
        ZStack {
            // 半透明背景（タップで閉じる）
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // メニューコンテンツ
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // 上段: 食べ物をスキャン、運動を記録、手動で入力
                    HStack(spacing: 0) {
                        RecordMenuButton(icon: "camera.viewfinder", title: "食事を撮影", color: Color(UIColor.label)) {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                navigateToCamera = true
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        RecordMenuButton(icon: "figure.run", title: "運動を記録", color: .green) {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                navigateToExerciseMenu = true
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        RecordMenuButton(icon: "pencil", title: "手動で入力", color: .pink) {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                navigateToManualRecord = true
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 40)
                    
                    // 下段: 保存済み、体重を記録
                    HStack(spacing: 60) {
                        RecordMenuButton(icon: "bookmark", title: "保存済み", color: Color(UIColor.label)) {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                navigateToSavedMeals = true
                            }
                        }
                        
                        RecordMenuButton(icon: "scalemass", title: "体重を記録", color: .purple) {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                navigateToWeightRecord = true
                            }
                        }
                    }
                }
                .padding(.bottom, 70)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllMealScreens)) { _ in
            isPresented = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllExerciseScreens)) { _ in
            isPresented = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissAllWeightScreens)) { _ in
            isPresented = false
        }
    }
}

// MARK: - メニューボタン
struct RecordMenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 56, height: 56)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}
