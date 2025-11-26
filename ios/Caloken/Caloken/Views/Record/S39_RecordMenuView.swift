import SwiftUI

struct S39_RecordMenuView: View {
    // @Environment(\.dismiss) var dismiss  // コメントアウト
    @State private var showCamera = false
    @State private var showManualRecord = false
    @State private var showWeightRecord = false
    @State private var showExerciseMenu = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ヘッダー（削除 - タブビューなので不要）
                /*
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                */
                
                // メニュー項目
                ScrollView {
                    VStack(spacing: 20) {
                        RecordMenuItem(
                            icon: "camera.fill",
                            title: "食事を撮影",
                            subtitle: "写真から自動で栄養素を分析",
                            color: .orange
                        ) {
                            showCamera = true
                        }
                        
                        RecordMenuItem(
                            icon: "keyboard",
                            title: "手動で記録",
                            subtitle: "食事内容を手入力",
                            color: .blue
                        ) {
                            showManualRecord = true
                        }
                        
                        RecordMenuItem(
                            icon: "figure.run",
                            title: "運動を記録",
                            subtitle: "ランニングやトレーニング",
                            color: .green
                        ) {
                            showExerciseMenu = true
                        }
                        
                        RecordMenuItem(
                            icon: "scalemass",
                            title: "体重を記録",
                            subtitle: "体重の推移を記録",
                            color: .purple
                        ) {
                            showWeightRecord = true
                        }
                        
                        RecordMenuItem(
                            icon: "bookmark.fill",
                            title: "保存済みから選択",
                            subtitle: "よく食べる食事を選択",
                            color: .gray
                        ) {
                            // 保存済み画面へ
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .background(Color.appGray)
            .navigationTitle("記録")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)  // .inline → .large に変更
            #endif
        }
        .sheet(isPresented: $showCamera) {
            S45_CameraView()
        }
        .sheet(isPresented: $showManualRecord) {
            S48_ManualRecordView()
        }
        .sheet(isPresented: $showWeightRecord) {
            S49_WeightRecordView()
        }
        .sheet(isPresented: $showExerciseMenu) {
            S40_ExerciseMenuView()
        }
    }
}

struct RecordMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(color)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    S39_RecordMenuView()
}
